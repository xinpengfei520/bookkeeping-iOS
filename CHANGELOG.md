# Changelog

本项目所有版本更新记录于此文件。

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/spec/v2.0.0.html)。

类别约定：**新增** / **变更** / **修复** / **移除** / **安全**。

---

## [Unreleased]

（暂无未发布改动）

---

## [1.0.7] (build 8) — 2026-05-09

### 新增
- **WidgetKit 替代 Today extension**: 老的 Today extension（`NCWidgetProviding` + UIKit + XIB）自 iOS 14 起被系统 widget gallery 隐藏，iOS 17 起彻底移除——这也是用户反馈"小组件搜不到"的根因。整体迁移到 WidgetKit (Swift + SwiftUI)：`BookMonthWidget.swift` (`@main` WidgetBundle) / `BookMonthProvider.swift` (TimelineProvider，30 min refresh) / `BookMonthEntryView.swift` (SwiftUI 视图)。提供 `.systemSmall` + `.systemMedium` 两档；大月份 + 收/支/结余三行 + 绿色 "记一笔" 按钮的视觉跟老 widget 保持一致。`kbook://month` URL scheme 不变，AppDelegate 路由零改动。
- **Widget 即时跟随主 app 主题与语言切换**: 新增 `Classes/Utils/WidgetReloader.swift`（`@objc(WidgetReloader)` shim 暴露 `WidgetCenter.shared.reloadAllTimelines()` 给 OC，因为 `WidgetCenter` 是 Swift-only `public final class`）。`LanguageSettingsController` / `ThemeSettingsController` 在保存偏好后调一次 reload，下一个 runloop tick widget 就跟着翻，不用等自然 30 min 缓存过期。
- **Widget 主题独立于 iOS 系统**: WidgetKit 进程的 `UITraitCollection` 由系统决定、跟主 app 的 `window.overrideUserInterfaceStyle` 互不通气。`BookMonthEntry` 现在携带 `preferredScheme`（从共享 suite 读 `kk_app_theme_mode`），`BookMonthEntryView` 用 SwiftUI 原生 `.primary` / `.secondary` 替代 `Color(.label)` / `Color(.secondaryLabel)`（UIKit-bridged 色不听 `\.colorScheme` env override），背景按 `effectiveScheme = preferredScheme ?? systemScheme` 直接算字面色。结果：主 app 选「深色」widget 立即变深，跟系统当前模式无关。

### 重构
- **Home headers XIB → code (pilot)**: `HomeHeader.xib` + `HomeListHeader.xib` 转纯代码 Masonry 实现。两个 XIB 删除（净 -106 行）。`HomeListHeader` 改走 `UITableViewHeaderFooterView` 的 `registerClass:` + `dequeueReusableHeaderFooterViewWithIdentifier:` 标准 cell 复用，替代以前的 `loadFirstNib:table:`。`CLAUDE.md` 同步加 "no new XIB" convention：新视图全代码，已有 XIB 视情况按需转换；列出 XIB 三大维护痛点（i18n grep 漏扫 / `systemColor` 烘焙 / IBOutlet 重命名 silent drift）。
- **首页 section header 背景色对齐 cell**: pilot 转换初版用了 `systemGroupedBackgroundColor`（浅色 sRGB ≈ 0.949 浅灰）跟 cell 的 `systemBackgroundColor`（纯白）有色差。改成两者一致：`backgroundView` 用 `systemBackgroundColor`，line 保留 `systemGroupedBackgroundColor` 作底部 0.5pt 分隔。

### 内部
- **主 app 改为 OC + Swift 混编**: `SWIFT_VERSION = 5.0` 加到 bookkeeping target；自动生成 `bookkeeping-Swift.h`；OC 文件可 `#import "bookkeeping-Swift.h"` 调 `@objc` 暴露的 Swift 类。
- **Widget target 也是 OC + Swift 混编**: 通过 `BookMonth-Bridging-Header.h` 让 Swift 复用主 app 已有的 OC 数据层（`BookDetailModel` / `BookMonthModel` / `KKI18n` 等已编进 widget Sources），不重写一份业务逻辑。
- **pbxproj**: `bookkeeping` target 链接 `WidgetKit.framework`；`BookMonth` target 链接 `WidgetKit.framework` + `SwiftUI.framework`，移除 deprecated `NotificationCenter.framework`。两侧 `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES`（extension 自己不能带 Swift runtime，必须从主 app 继承）。
- Widget Info.plist：`NSExtensionPointIdentifier` `com.apple.widget-extension` → `com.apple.widgetkit-extension`，删除 `NSExtensionPrincipalClass`（WidgetKit 用 `@main` 不再需要 principal class）。

---

## [1.0.6] (build 7) — 2026-05-09

### 新增
- **多语言支持（中文 / 英文）**：Me → 语言：跟随系统 / 简体中文 / English。基于 `KKI18n` 内存字典实现：中文原文即 key，`KKLocalized()` 宏全局调用；切换语言后弹窗"语言已切换 — 需要重启 App 后完全生效"，确认即 `exit(0)`。共本地化 286 处字面量、217 个唯一字符串（覆盖首页 / 记账 / 账单 / 图表 / 个人中心 / 类别 / 导出 / 反馈 / 登录 / 密码 / 定时 / 验证 / 关于 / 删除账号 / Widget 等全部用户可见界面）。语言偏好存于共享 App Group `group.xpf.widget`，widget 与主 app 同步。
- **深色模式（Light / Dark / 跟随系统）**：Me → 深色模式：跟随系统 / 浅色 / 深色。基于 `KKTheme` + `window.overrideUserInterfaceStyle`，**切换瞬间生效，无需重启**。`KKPrefixHeader.pch` 中 8 个语义色宏（`kColor_BG` / `kColor_Line_*` / `kColor_Text_Black/Gary/Light` / `kColor_Chart_*`）改写为 `colorWithDynamicProvider:` 动态色，trait collection 变化时自动重解析。品牌色（`kColor_Main_*`）/ 警示色（`kColor_*Red*`）/ 绿底白字（`kColor_Text_White`）保持跨模式一致。

### 变更
- **最低适配 iOS 版本：15.6 → 16.0**：主 app pbxproj 4 处、widget pbxproj 同步、Podfile platform + post_install hook 全部对齐 16.0。`pod install` 全量重整 Pods.xcodeproj（diff 是纯字段翻转）。
- **硬编码静态颜色审计**（仅 `Classes/`，跳过 `Third/`）：
  - 15 处 `[UIColor whiteColor]` 用作背景 → `systemBackgroundColor`（含 `view.backgroundColor =` 与 `setBackgroundColor:` 两种语法）。
  - 4 处 `textColor = [UIColor lightGrayColor]` → `secondaryLabelColor`。
  - 4 处 `borderColor = [UIColor lightGrayColor].CGColor` → `separatorColor.CGColor`。
  - 2 处 `setTitleColor:[UIColor lightGrayColor]` → `secondaryLabelColor`。
  - 保留 3 处 `whiteColor`：WebView 进度条 / 导出按钮文字（绿底白字）/ JGProgressHUD 三方代码。

### 修复
post-merge 阶段联调发现 + 修复：
- **Widget 编译失败 `'KKI18n.h' file not found`**：BookMonth target 没有显式 `USER_HEADER_SEARCH_PATHS`，历史靠 Xcode 隐式 header map 凑合，新加的 `.h` 命中率不可靠。给 widget Debug/Release 两套 config 显式列入 `Classes/Utils` / `Categorys/*` / `Base/*` / `Modules/*/Model` 等主 app 目录，从此添加新主 app 头文件 widget 不再炸。顺便兑现了 README backlog 里 "BookMonth widget header path" 历史 TODO。
- **PCH 编译失败 `Unknown type name 'NS_INLINE'`**：`KKDynamicColor` 内联函数原本放在 `#import "Common.h"` 之前，UIColor / Foundation 类型还没引入。挪到 import 之后，`#define kColor_*` 文本宏保持原位（在使用点延迟展开，顺序无关）。
- **`MineController` 反馈邮件正文编译失败 `Expected ']'`**：Phase 2C wrap 脚本误把 `[NSString stringWithFormat:@"..." @"App版本：%@\n" @"系统版本：…" ...]` 这种 Objective-C 字面量拼接里的中文段替换成 `KKLocalized(...)` 函数调用，破坏拼接。改为 `NSMutableString.appendFormat` 增量构造（每段独立本地化）。全仓 audit 只有这一处踩雷。
- **首页顶部布局随语言切换走形**：`@"月": @""` 让 `monthDescLab` intrinsic 尺寸坍缩到 0，XIB 里几个 centerY 锚定它的元素跟着飘。改 `@"月": @"Mo."` 保持视觉宽度，并给 `monthDescLab` 加 widthAnchor / heightAnchor 最小尺寸约束；任何语言下的 header 视觉一致。
- **首页记账列表分组 header 不跟随深色模式**：`HomeListHeader.xib` 用 `groupTableViewBackgroundColor`（被 Xcode 烘焙成静态 sRGB），`HomeListCell` 表格 / footer 写死 `kColor_White`。改为 `systemGroupedBackgroundColor` / `systemBackgroundColor` 三处。
- **个人中心新加的语言 / 深色模式行图标颜色不搭**：SF Symbol 用 `kColor_Text_Black` tint，与同栏品牌绿 PNG 资产风格冲突。改 tint 为 `kColor_Main_Color`，symbol 加 22pt SymbolConfiguration，`moon.circle` → `moon.fill`。
- **XIB 写死的中文字面量 i18n 漏扫**：Phase 2C wrap 脚本只扫 `.m/.h`，XIB 里 `text=` / `placeholder=` / button title / segment title 全漏。本轮在 14 个模块的 `initUI`/`setupUI` 里加 `KKLocalized()` 覆盖（Bill / Book / Category / Chart / Detail / Register / Share / Timing / AddCategory / Home / Info）。剩 6 处无 IBOutlet 的 XIB-only label 留待按需处理。

### 内部
- 新增 `Classes/Utils/KKI18n.{h,m}`、`KKTheme.{h,m}`；`Modules/Me/Controller/LanguageSettingsController.{h,m}`、`ThemeSettingsController.{h,m}`。
- `MineTableView` 接入 SF Symbol 图标（`sf:` 前缀），section 1 增加 "语言" / "深色模式" 两行（`sf:globe` / `sf:moon.fill`）。
- pbxproj 文件注册全部通过 `xcodeproj` Ruby gem，避免手工编辑出错。
- KKEnglishTable 累计 230+ 翻译条目（含本轮 XIB 补量 14 条）。

---

## [1.0.5] (build 6) — 2026-05-09

### 修复
- **首页 + 按钮 → 记账页**下拉关闭时"下拉关闭页面 / 松开关闭页面"文字消失（1.0.4 P5 回归）。BKCCollection 改用 `KKPullToRefreshHeader` 同时承担文字提示与 dismiss/pop 触发；触发阈值从 `offsetY < -54` 调整为 `-70`（header height 50 + trigger inset 20，与首页 HomeListCell 一致）。

### 内部
post-1.0.4 cleanup（不影响行为）：
- `Common.h` 删除重复的 `NSAttributedString+Extension` import。
- `NSString+API.h` 删除 12 个 0 引用的旧 `/shayu/*` 接口宏（`CreateBook` / `GetBookList` / `getBookGroup` / `AddSystemCategory` / `ForgetPass` / `BindThird` / `BindPhone` / `Sound` / `Detail` / `Time{List,Add,Remove}`）。
- `NSString+API.h` 集中 6 个 web/外链宏（`kAgreementURL` / `kPrivacyURL` / `kTermsOfServiceURL` / `kPrivacyPolicyURL` / `kHelpURL` / `kAppStoreURL`），替换 `MineController` / `PasswordLoginController{1,2}` / `AgreementWebViewController` 共 8 处硬编码 URL。
- `KKPrefixHeader.pch` 删除 6 个未接 trait collection 的 night-mode 占位色（`kColor_Night_Back_*` / `kColor_Cell_High_{Light,Night}` / `kColor_Line_Night`），保留单行 TODO 注释。
- 最后 4 处裸 `[[NSNotificationCenter defaultCenter] addObserver:self ...]` 迁移到 P4 自家 `kk_observeNotification:usingBlock:`（`BookController` + `BKCKeyboard` 的键盘 show/hide 监听），同步移除两处仅含 `removeObserver:self` 的 `-dealloc`。
- `BaseTableCell` 接管 `selectionStyle = None`；移除 10 个 cell 子类重复设置；其中 4 个原直继承 `UITableViewCell` 的 cell（`HomeListSubCell` / `CategoryCell` / `SearchListSubCell` / `TITableCell`）改继承 `BaseTableCell`。
- 净 −68 LoC。

---

## [1.0.4] (build 5) — 2026-05-08

### 变更
- **下拉刷新 / 上拉加载体验调整**：首页月份切换的 idle 状态默认不显示文字（footer 看起来不存在）；用户开始拉拽时显示 `下拉/上拉切换X月数据`，过阈值后变 `松开切换X月数据`；松手即触发；菊花最少显示 0.4 秒，避免同步链路把 spinner "瞬间关掉"。

### 移除
- `ReactiveObjC 3.1.0` 第三方依赖（停滞维护，自 2018 年起未更新）。替换为三个轻量自家 helper：`KKWeakify.h`（`@weakify`/`@strongify` 单参数版）、`NSObject+KKObserver`（NSNotificationCenter 块包装 + 自动 dealloc 解除监听）、`UIControl+KKBlock`（按钮事件块包装）。原 108 处 `@weakify`/`@strongify` 调用点保持不变。
- `MJRefresh 3.1.15.7` 第三方依赖。替换为两个自家 view：`KKPullToRefreshHeader` / `KKLoadMoreFooter`，共享 4 状态机（idle / pulling / willRefresh / refreshing）+ 0.4 秒最小 spinner 显示时长 + 自定义触发距离 70pt。
- 5 个原本继承 MJRefresh 的自定义子类：`KKRefreshGifHeader`（孤儿代码 + 60+3 GIF 帧也一并删）、`RequestTipRefreshFooter`、`KKRefreshNormalHeader`、`KKRefreshNormalFooter`、`BKCRefreshHeader`（仅装饰提示，dismiss 由 iOS 13+ modal 自带 swipe-down 接管，整段删除）。
- 63 个 `dropdown_anim__*` / `dropdown_loading_*` GIF 帧素材（仅 `KKRefreshGifHeader` 引用，跟着一起删）。

### 内部
- Pod 依赖从 9 → 7（剩 7 个：pop / SDWebImage / Masonry / MJExtension / JGProgressHUD / BRPickerView / Bugly，README 第七节有保留理由说明）
- 第三方源码累计净减约 165K LoC
- 文档：README 第七节 backlog 同步更新；移除 P4/P5 待办项

---

## [1.0.3] (build 4) — 2026-05-08

### 变更
- **头像选择 UI** 替换为系统组件：相册路径 → `PHPickerViewController`（iOS 14+，运行在沙箱外、无需相册权限弹窗），拍照路径 → `UIImagePickerController`。视觉与交互切换为系统原生风格。
- **列表侧滑删除** 替换为系统 `UISwipeActionsConfiguration` + `UIContextualAction`（首页账单 / 类别设置 / 定时提醒三处），动画与按钮样式回归 iOS 系统原生表现。
- **类别设置：操作按钮二次确认** 简化：之前点 cell 上的 "−" 操作按钮会先展开侧滑做二次确认，现在直接触发删除。系统 API 没有"程序触发侧滑"的等价方法；用户已经主动点了明确的删除操作按钮，简化掉一次确认更直接。

### 修复
- **首页点击收入/支出数值进入图表页闪退**（`NSRangeException: index 18446744073709551615 beyond bounds [0 .. 6]`）：`BookChartModel.statisticalChart:` 在脏数据下计算出负数下标后 NSUInteger 溢出。三个分支（周/月/年）全部加上边界 guard，遇到 `weekday < 1 || > 7` / `day < 1 || > daysInMonth` / `month < 1 || > 12` 直接 `continue` 跳过，不让单条脏数据把整个图表搞崩。

### 移除
- `SDCycleScrollView 1.75` 第三方依赖（孤儿，0 业务调用）
- `YYImage 1.0.4` 第三方依赖（孤儿，0 业务调用）
- `ZLPhotoBrowser` 第三方依赖（替换为系统 PhotosUI / ImagePickerController；少 1 个 Swift 依赖）
- `MGSwipeTableCell 1.6.8` 第三方依赖（替换为 iOS 11+ 系统 API）

### 内部
- Pod 依赖从 14 降到 9（间接依赖也跟着减少；第三方源码累计净减约 36K LoC）
- 文档：README 第七节"重构 backlog" 同步更新；新增 P4 (ReactiveObjC 替换) / P5 (MJRefresh 替换) 待办；记录 Bugly 仍可用、暂不替换

---

## [1.0.2] (build 3) — 2026-05-08

### 变更
- **导航层架构重写**：移除 HBDNavigationBar 与 KMNavigationBarTransition 第三方依赖，`BaseNavigationController` 改回原生 `UINavigationController`，全局通过 `UINavigationBarAppearance` 统一品牌色（不透明绿底 + 白字标题）。
- **24 个 ViewController** 的导航条配置统一：`hbd_barHidden` → `prefersNavigationBarHidden` 自有属性；`setNavTitle:` → 系统 `self.title`；customView 方式的 bar button → 系统 `UIBarButtonItem`（CAController / ACAController 用 `Done` 风格、BillController 年份+箭头复合按钮包成 `customView` 包装、WebViewController 左侧返回链式按钮接 `handleBackAction`）。
- **`BaseViewController` 显著瘦身**（152 → ~40 行）：移除 `leftButton` / `rightButton` / `setNavTitle:` / `initUI` / `hideNavigationBarLine` 等历史 API；只保留 `viewDidLoad` / `viewWillAppear:` / `dealloc` 三段。

### 新增
- **iOS 26 视觉降级开关**：在 `Info.plist` 加入 `UIDesignRequiresCompatibility = YES`，让系统 bar item / button 在 iOS 26 上保持 iOS 25 经典风格，避免 Liquid Glass 玻璃容器与品牌色冲突。

### 修复
- **个人中心可达性**：MineController 历史上没有自带返回按钮，又因隐藏导航条丢失系统侧滑返回手势——补一个白色 chevron 返回按钮 + 在 `BaseViewController` 里为所有隐藏导航条页面恢复 `interactivePopGestureRecognizer`。
- **头像与返回按钮重叠**：`MineTableHeader` 头像 left 偏移从 20pt 调到 64pt，避让左上角新增的返回按钮。

### 移除
- HBDNavigationBar (`~> 1.9.5`) 第三方依赖
- KMNavigationBarTransition (`1.1.5`) 第三方依赖
- Podfile post_install 里 HBD KVC `@try/@catch` patch hook（不再需要）

---

## [1.0.1] (build 2) — 2026-05-07

### 新增
- **`app_id` 全局请求头**：所有走 `AFNManager` 的请求自动携带 `app_id: 638c2977f1b24ba0`。
- **`CLAUDE.md` 项目说明**：用于 IDE / AI 协作上下文。

### 变更
- **AFNManager 重写**：由 AFNetworking 4.0.1 切到系统 `NSURLSession`。三个 `+ POST:` 公开签名完全保持兼容，21 处调用点 0 修改。`Authorization` 自动刷新、`app_id` 头、`MINE_TOKEN_EXPIRED` 通知契约、`APPResult` MJExtension 解码、multipart 上传与上传进度 callback 全部对齐原 AFN 行为；失败路径新增 `NSLog` 诊断信息。
- **头像上传 multipart 改为 JPEG 优先**（quality 0.85 + PNG fallback），原 PNG 优先在生产环境从未真正工作过（被 nginx 413 反弹）。
- **客户端预压缩**：头像上传前先缩放到 512px 最长边。

### 修复
- **iOS 26 Liquid Glass 浮动玻璃按钮**遮挡页面内自定义关闭/操作按钮：`BaseViewController.viewWillAppear:` 中对隐藏导航条页面统一清掉 `leftBarButtonItem` / `rightBarButtonItem` / 系统默认 back 按钮。
- **iOS 26 HBDNavigationBar 闪退**：`valueForKeyPath:@"visualProvider.contentView"` 不再 KVC 兼容 → 用 `@try/@catch` 包住、失败返回 nil（调用方有 nil 防护）。
- **Xcode 16 / iOS 26 SDK 下的多种编译错误**：
  - YYText 1.0.7 / Texture `ASTextLayout.mm` 链式比较 `A < B < C` 被升级为 error → 自动 patch 修正为三元表达式
  - AFNetworking 4.0.1 `<netinet6/in6.h>` 私有头 import 在新 SDK 下报错 → 自动 patch 删除
  - CocoaPods bundle target 在 Xcode 15+ 强制要求签名 → 全局关闭 `CODE_SIGNING_ALLOWED`
- **ZLPhotoBrowser 相册路径闪退**：`selectImageBlock` 实际传入的是 `[ZLResultModel]` 而非 `[UIImage]`，旧调用点直接传给 `UIImagePNGRepresentation` 触发 `unrecognized selector`。修正为 `images[0].image`。

### 移除
- YYText 1.0.7 第三方依赖（在 App 业务代码中 0 引用）
- Texture (AsyncDisplayKit) 3.1.0 第三方依赖（`ASBaseViewController` / `ASBaseTableCell` 0 子类）
- AFNetworking 4.0.1 第三方依赖
- 间接依赖：PINCache / PINOperation / PINRemoteImage（Texture 的传递依赖）
- Podfile post_install 里 YYText / Texture / AFNetworking 三组源码 patch hook

---

## [1.0.0] (build 1)

首发版本（本 changelog 创建之前的累计内容）。
