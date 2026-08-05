# iOS 回复 —— 🚨 请紧急恢复裸 token 兼容分支

> 回复方：iOS 端
> 日期：2026-08-05
> 对应文档：`bookkeeping-SpringBoot/docs/prd/后端答复-iOS待确认问题.md`
>
> **结论：问题一 / 一b / 二 全部确认无误，客户端零改动，感谢。**
> **但第四条「移除裸 token 兼容」会让 1.0.8 及更早版本的用户全部无法使用，请立即回滚该项。**

---

## 🚨 紧急：裸 token 兼容必须恢复

你们问「如果还有任何尚未升级、仍在发裸 token 的版本在外面跑，请立刻告知」——
**有，而且不是少数：iOS 1.0.8 及之前的所有版本都会中招。**

### 为什么老客户端会发裸 token

iOS 1.0.9 才引入「只存裸 JWT、发送时拼一次 `Bearer `」。在那之前（≤ 1.0.8）的实现是
**把响应头的值原样存下、原样回填**，三段代码如下（取自 tag `1.0.8`）：

```objc
// UserInfo.m —— 原样存，不做任何处理
+ (void)saveAuthorizationToken:(NSString *)authorization {
    [NSUserDefaults setObject:authorization forKey:AUTHORIZATION_TOKEN];
}
+ (NSString *)getAuthorizationToken {
    return [NSUserDefaults objectForKey:AUTHORIZATION_TOKEN];
}

// AFNManager.m —— 原样回填到请求头，不拼前缀
NSString *auth = [UserInfo getAuthorizationToken];
[req setValue:auth forHTTPHeaderField:@"Authorization"];

// AFNManager.m —— 每个响应都会用响应头刷新本地 token
if ([headers.allKeys containsObject:@"Authorization"]) {
    [UserInfo saveAuthorizationToken:headers[@"Authorization"]];
}
```

这套代码在服务端 v1.1.0 **之前**是正确的：那时响应头下发的是 `Bearer eyJ...`，
存下来原样回填，发出去就是 `Bearer eyJ...`，一切正常。

**v1.1.0 把响应头改成裸 JWT 之后，这套代码就自动开始发裸 token 了。**

### 失效是必然的，不是概率问题

关键在最后那段：老客户端会用**每一个**响应的 `Authorization` 头覆写本地 token。
所以老版本用户只要发起过任何一次带该响应头的请求（登录必然带，token 续签也带），
本地 token 就从 `Bearer eyJ...` 变成了裸 `eyJ...`，此后**所有**请求都会被 v1.1.1 拒绝。

而且用户**无法自救**：

- 重新登录 → 再次存下裸 token → 依然失败，死循环；
- 返回的是 `4001`，不是 `5001 TOKEN_EXPIRED` → 老客户端不会走「登录过期」流程，
  只会在各个页面弹一个「Authorization格式不正确」的 toast，用户完全不知道该做什么；
- 卸载重装也没用，代码就是这么写的。

**净效果：≤ 1.0.8 的用户，App 变成完全不可用（能打开，但任何联网操作都失败）。**

### 时间线

| 版本 | 客户端行为 | v1.1.0（兼容期） | v1.1.1（已移除兼容） |
|---|---|---|---|
| ≤ 1.0.8（2026-05-10 及更早） | 原样存、原样发 | ✅ 裸 token 被接受 | ❌ **全部失效** |
| ≥ 1.0.9（2026-08-04 起） | 只存裸 JWT，发送拼 `Bearer ` | ✅ | ✅ |

1.0.8 是 2026-05-10 发布的，到今天不足三个月，App Store 上必然还有相当比例的用户停留在该版本或更早。

### 请求

1. **立即把裸 token 的兼容分支加回去**（v1.1.2 或热修）；
2. 兼容分支**不要**再按「各端已改完」来判断移除时机，而是以**数据**为准 ——
   我们会在 App Store Connect 里查 ≤ 1.0.8 的活跃占比，等它降到可接受阈值（比如 <1%）
   再一起商量移除，届时提前一个版本周期通知；
3. 移除前如果能在服务端加一条埋点（收到裸 token 时记 warn 日志 + 计数），
   我们就能用真实数据判断，而不是靠推测。

---

## 其余三条：确认无误，客户端零改动 ✅

我们逐条比对了客户端当前实现（1.0.17），确认与你们的新行为完全兼容。

### 问题一：按需清空 —— 我们的请求天然命中「改了金额」分支

客户端的 update 请求体是**全量构建**的，`price` 永远在里面：

```objc
// HomeController.saveParamsWithModel: —— update 与离线补发共用
param[@"year"] / [@"month"] / [@"day"] / [@"price"] / [@"mark"] / [@"categoryId"]
// 外币记录额外追加（isForeignCurrency 为真时）
param[@"currency"] / [@"originalPrice"] / [@"exchangeRate"]
// update 再补上 bookId
```

因此三种编辑场景的实际表现：

| 场景 | 客户端实际发出 | v1.1.1 结果 |
|---|---|---|
| 外币 → 人民币 | `price` + **不给**三字段 | 三列清空 ✅ 正是我们要的 |
| 改外币金额 | `price` + 三字段齐全 | 正常更新 ✅ |
| 外币记录只改备注 | 仍然是 `price` + 三字段齐全（我们不做部分提交） | 走「改了金额」分支，但值没变，等价于原样 ✅ |

你们加的「只改金额时才重写」这个限定条件，是为**部分提交**的客户端准备的保护 ——
我们从不部分提交，所以永远走全量语义分支，行为反而更可预测。这个设计我们认同，
对第三方调用方是必要的保护。

### 问题一 b：新校验对客户端无影响

新增的「给了三件套却不给 `price`」这条，客户端不可能触发（`price` 永远在请求里）。
其余三条 save 已有的规则我们本来就在遵守（三字段全给或全不给、`currency` 大写、
`price = round(originalPrice × exchangeRate, 2)` 且直接使用接口返回的 6 位汇率）。

顺带说明：客户端有一个**离线待办队列**，弱网时的增/改/删会排队、联网后自动补发。
补发 update 时用的是同一套全量请求体，所以同样满足新校验。若补发时收到 `4001`，
客户端会把该条移出队列并提示用户（不会无限重试）。

### 问题二：BCrypt —— 此条关闭 ✅

结论一致，客户端不做任何哈希。cost 保持 10 的判断我们也认同。

---

## 汇总

| # | 结论 | 需要谁改 |
|---|---|---|
| 1 | 按需清空已生效，客户端天然兼容 | 无 |
| 1b | 新校验客户端不会触发 | 无 |
| 2 | BCrypt 达标，关闭 | 无 |
| — | 🚨 **裸 token 兼容需立即恢复** | **后端（紧急）** |

麻烦优先处理最后一条，其余都已闭环。恢复上线后告知一声，我们这边不需要发版。
