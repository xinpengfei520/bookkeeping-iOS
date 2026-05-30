# 复盘：首页日期"星期X"偶发不显示 / 显示错误

> 时间：2026-05
> 影响范围：首页（HomeController）月度账单列表的日期分组表头 `HomeListHeader`
> 状态：已修复并验证

---

## 一、问题现象

首页按天分组的列表，每个分组表头形如 `05月26日   星期二`。用户反馈：

- 有些表头**只显示日期、不显示星期**（如 `05月23日` 后面是空的）。
- 偶尔显示**错误的星期**（如 `05月26日` 显示成 `星期三`，正确应为 `星期二`）。
- **滚动后更明显**：第一屏正常，往下滑动后下面的星期消失；滑回顶部，原本正常的也变空。
- 账目条目（图标 / 备注 / 金额）一切正常，**只有表头的"星期"会丢**。

## 二、根本原因（最终确认）

**星期是通过反复创建 `NSDate` / `NSCalendar`（早期是 `NSDateFormatter`）来计算的；在列表快速滚动、表头被高频反复渲染时，这些日期对象偶发构造/解析失败返回 `nil`，导致 `[date dayFromWeekday]` 落到 `default` 分支返回空串 `@""`，星期被静默丢弃。**

旧实现（简化）：

```objc
- (NSString *)getDateDescribe {
    NSString *s = [NSString stringWithFormat:@"%ld-%02ld-%02ld", _year, _month, _day];
    NSDate *date = [NSDate dateWithYMD:s];          // 反复创建 NSDateFormatter 解析
    return [NSString stringWithFormat:@"%02ld月%02ld日   %@",
            _month, _day, [date dayFromWeekday]];   // date 为 nil 时返回 @""
}
```

定位它的关键证据（来自加在 `HomeListHeader` 的诊断日志）：

| 证据 | 说明 |
|---|---|
| `setModel text='05月27日   '` | **字符串本身就缺星期**，不是被裁剪/遮挡 |
| `text='05月25日   星期一'` 同时存在 | 说明计算路径本身能算对，只是**偶发**失败 |
| 同一个 section（同一 model、同样年月日）一会儿有星期、一会儿没有 | **非确定性** |
| `nameLab.frame` 宽度随文字长短正确变化、`hidden=0 alpha=1` | **布局没有问题**，排除截断/塌缩 |
| 金额（`getMoneyDescribe`，不碰日期对象）**始终正常** | 失败只发生在用到日期对象的那一项 |

"非确定性 + 只有日期项失败 + 金额永远对" 正是 `NSDateFormatter` / `NSCalendar` 这类 ICU 日期对象在**高频反复创建 / 非线程安全场景**下不稳定的典型特征。在 cell/header 渲染热路径里反复创建它们是公认的反模式。

## 三、排查过程与走过的弯路（重点）

这个问题表面像"日期计算 bug"，实则是"渲染期日期对象不稳定"。期间提出并**逐一排除**了多个看似合理的假设——记录下来是为了避免下次再绕：

1. **时区假设**：`dateWithYMD` 用 GMT 解析，`weekday` 用本地日历取值，时区不一致。
   → 确为潜在 bug（非 UTC+8 设备会错一天），但用户是 UTC+8，**非本例主因**。
2. **非公历假设**：`NSDateFormatter` 未固定 `locale/calendar`，设备日历若是非公历（如中华民国历，`2026` 被当成民国 2026=公元 3937 年）会把星期算错甚至返回 nil。
   → 用独立程序复现："中华民国历"能精确复现出错误的 `星期三`。确为潜在 bug，但用户设备确认是**公历**，排除为主因。
3. **脏数据假设**：`All_BOOK_LIST` 里混入了错误/缺失年份的记账。
   → 加临时诊断日志确认数据 **100% 干净**（10354 条，年份仅 2018–2026，0 异常，过滤正常返回 48 条），排除。
4. **表头复用/布局塌缩假设**：`UITableViewHeaderFooterView` 复用时 `contentView` frame 归零、label 被压扁。
   → 加 `layoutSubviews` 日志确认 label frame、可见性都正常，**布局无问题**，排除。
5. **最终**：日志显示"字符串本身缺星期 + 非确定性 + 金额永远对"，锁定为**日期对象在渲染热路径上的不稳定**。

> 教训：同一处代码确实**同时存在多个潜在隐患**（时区、非公历、对象不稳定），且症状叠加（错 + 空）。在拿到日志 / 复现之前，多轮"基于推理的修复"都失败了；真正起作用的是**加诊断日志拿到 ground truth**。

## 四、修复方案

用**纯整数算法（Sakamoto / 蔡勒同余思路）**直接由 年/月/日 计算星期，**完全不创建** `NSDate` / `NSCalendar` / `NSDateFormatter`：

```objc
static NSString *KKWeekdayCN(NSInteger year, NSInteger month, NSInteger day) {
    static const NSInteger t[12] = {0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4};
    NSInteger y = (month < 3) ? year - 1 : year;
    NSInteger idx = (month >= 1 && month <= 12) ? (month - 1) : 0;
    NSInteger w = (((y + y/4 - y/100 + y/400 + t[idx] + day) % 7) + 7) % 7; // 0=周日..6=周六
    switch (w) {
        case 0: return KKLocalized(@"星期日");
        // ... 1..6 → 星期一..星期六
        default: return @"";
    }
}
```

特点：**结果确定、线程安全、绝不为 nil/空**；即使年份非法（如 0）也返回合法星期。

应用位置：

- `BookMonthModel.getDateDescribe`（首页表头）
- `BookMonthModel.getDateDescribeWithYear`（搜索结果表头）
- `BookDetailModel.getDateStr`（明细页）

附带保留的**防御性修复**：`NSDate+Extension.createDateWithFora` 强制公历 + `en_US_POSIX`，修的是上面第 2 条"非公历设备"隐患，保护项目里其它仍在用 `dateWith*` 的地方。

已**回退**：`HomeListHeader` 表头改动（布局本无问题，无需改动）。

## 五、验证

- 独立程序验证 Sakamoto 对 2026-05 全月正确：`20=三 21=四 22=五 23=六 24=日 25=一 26=二 27=三 28=四 29=五 30=六`，与截图一致并补齐了原先空白的几天；`year=0` 返回"星期六"（不空）。
- 真机滚动测试：星期**始终显示、不再消失**。

## 六、经验教训 / 预防

1. **不要在 cell / header 渲染热路径里反复创建 `NSDateFormatter` / `NSCalendar`** —— 昂贵且不稳定。需要日期处理时：缓存单例 formatter，或像本次一样改纯计算。
2. **警惕"静默兜底"**：`dayFromWeekday` 的 `default → @""` 把"日期解析失败"伪装成"正常但没星期"，掩盖了真正的失败。兜底应当可观测（日志 / 断言），而不是悄悄返回空。
3. **先拿 ground truth 再动手**：基于症状的多次推理式修复都改错了；加诊断日志后一次定位。这是系统化调试的铁律——**没有根因就不要改**。
4. **后续收尾**：
   - ✅ 已完成：把 `KKWeekdayCN` 收敛为公共方法 `NSDate (Extension) +kk_weekdayCNFromYear:month:day:`，`BookMonthModel.m` / `BookDetailModel.m` 不再各留 `static` 拷贝，统一调用它。
   - ✅ 已完成：`NSDate+Extension` 的老写法 `dayFromWeekday:` 改为**委托**给 `kk_weekdayCNFromYear:`——"星期X"字符串只剩一处来源，不再静默返回空；`weekday:`（返回 1–7 的整数，供周计算用）保持不变以免影响 `weekOfYear` 等。
   - ⬜ 待办：全局审查其它"在列表渲染中创建日期对象"的位置。

## 七、涉及文件

| 文件 | 改动 |
|---|---|
| `Modules/Home/Model/BookMonthModel.m` | 新增 `KKWeekdayCN`；`getDateDescribe` / `getDateDescribeWithYear` 改用纯计算 |
| `Modules/Home/Model/BookDetailModel.m` | 新增 `KKWeekdayCN`；`getDateStr` 改用纯计算 |
| `Categorys/NSDate/NSDate+Extension.m` | `createDateWithFora` 强制公历 + en_US_POSIX（防御性） |
| `Modules/Home/View/Table/Header/HomeListHeader.m` | 临时诊断已移除，表头改动已回退 |
