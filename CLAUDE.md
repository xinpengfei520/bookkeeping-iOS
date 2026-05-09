# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build / Run

- Source root is `bookkeeping/`, **not** the repo root. CocoaPods is the dependency manager.
- First-time setup: `cd bookkeeping && pod install`, then open `bookkeeping/bookkeeping.xcworkspace` (never `.xcodeproj`).
- Build/run from Xcode. There is no test target — adding tests requires creating one first.
- Deployment target: iOS 16.0 (main app and BookMonth widget). Podfile platform and post_install hook enforce `IPHONEOS_DEPLOYMENT_TARGET = 16.0` for all pods.
- iPhone-only (`TARGETED_DEVICE_FAMILY = 1`); macOS support was removed.
- Simulator builds exclude `arm64` (`EXCLUDED_ARCHS[sdk=iphonesimulator*]`); Apple Silicon hosts must use Rosetta or run on device.
- Production API host is hard-coded in `bookkeeping/bookkeeping/Classes/Network/NSString+API.h` (`KHost`). The test host is commented out — toggle by editing the macro, there is no scheme-based switch.

## Targets

- **`bookkeeping`** — main app, bundle id `com.xpf.light.record`. Entry point: `AppDelegate` → `BaseNavigationController` rooted on `HomeController` (no `UITabBarController`; the home screen is the root).
- **`BookMonth`** — WidgetKit (Swift + SwiftUI) home screen widget, bundle id `com.xpf.light.record.BookMonth2`. Lives in `bookkeeping/BookMonth/`. The legacy Today extension (NCWidgetProviding / `MonthController` / XIB-driven `ContentView`) was deprecated by Apple in iOS 14 and removed entirely in iOS 17 — migrated to `BookMonthWidget.swift` (`@main` WidgetBundle), `BookMonthProvider.swift` (TimelineProvider, refresh ≈ 30 min), `BookMonthEntryView.swift` (SwiftUI views for `.systemSmall` + `.systemMedium`). Hybrid Swift + Objective-C: Swift views + Objective-C data models (`BookDetailModel` / `BookMonthModel` etc.) reused via `BookMonth-Bridging-Header.h`. Linked frameworks: WidgetKit + SwiftUI; legacy `NotificationCenter.framework` removed. Build settings: `SWIFT_VERSION = 5.0`, `SWIFT_OBJC_BRIDGING_HEADER = BookMonth/BookMonth-Bridging-Header.h`. Main app target carries `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES` so the extension inherits the Swift runtime. App Group `group.xpf.widget` shared NSUserDefaults still drives data flow. Communicates with the host app via the `kbook://` URL scheme (see `AppDelegate.m`): `kbook://month` opens the booking screen, `kbook://book` posts `NOTIFICATION_BOOK_ADD` (used as a kicker after main-app actions, not by the widget itself).

## Code Layout

All app source is under `bookkeeping/bookkeeping/Classes/`:

- `AppDelegate/` — app entry, root controller, Bugly init, URL scheme handling.
- `Base/` — `BaseViewController`, `BaseTabBarController`, `BaseNavigationController`, `BaseView`, `BaseTableView`, `BaseCollectionView`, `BaseModel`, plus `ASBaseViewController`/`ASBaseTableCell` (Texture/AsyncDisplayKit variants). New screens should subclass these.
- `Modules/<Feature>/{Controller,View,Model}/` — one folder per feature (Home, Chart, Book, Bill, Detail, Category, AddCategory, Search, Share, Export, Login, Verify, Register, Password, Me, Info, About, Feedback, Timing, WebView). Follow this MVC layout when adding features.
- `Network/` — `AFNManager` (singleton wrapping AFNetworking 4.0.1, JSON request/response, `Authorization` header from `UserInfo`), `APPResult` (response envelope), `NSString+API.h` (all endpoint macros), and `UIView/UIViewController+APPViewRequest` for view-attached requests.
- `Categorys/` — Foundation/UIKit categories. Many are auto-imported via `Common.h`; just create the `.h/.m` and add the `#import` there.
- `Common/` — shared UI: `Alert`, `BottomButton`, `Empty` (`KKEmpty` placeholder views), `Manager/LAContextManager` (Face ID / Touch ID), and a `Router 2/RouterProtocol.h`.
- `Third/` — vendored third-party code.
- `Utils/Single.h` — singleton macro.

## Architecture Conventions

- **Prefix header pattern.** `KKPrefixHeader.pch` is the project's PCH; it imports `Common.h`, which globally imports every base class, category, controller header, common util, and color/dimension macro. As a consequence, `.m` files rarely `#import` UIKit/Foundation/base classes — adding a new public controller, model, or category usually means adding it to `Common.h` so the rest of the project sees it.
- **Color & dimension macros.** All theming lives as `#define`s in `KKPrefixHeader.pch` (`kColor_Main_Color`, `kColor_BG`, `SCREEN_WIDTH`, `SafeAreaBottomHeight`, `NavigationBarHeight`, `countcoordinatesX(A)` for 375pt-baseline scaling, `RGBA(...)`, `HexColor(@"#...")`). Use these instead of inlining values; night-mode colors are pre-declared but not yet wired up (TODO in README).
- **Layout.** Masonry (`mas_makeConstraints:` / `mas_updateConstraints:`) — no SwiftUI, no Storyboards beyond `LaunchScreen`/`Main` shells. **New views are code-only: do NOT add new `.xib` files.** Existing `.xib`s remain (~30 of them), but each one is a known maintenance liability — XIB-baked strings escape the i18n grep (Phase 2C wrap script only scans `.m/.h`), `systemColor` references can get baked into static sRGB fallbacks (breaking dark mode), and IBOutlet drift is silent on rename. Convert opportunistically when touching a view for another reason; pilot pattern is `HomeHeader.m` / `HomeListHeader.m` (init → buildSubviews → initUI → set*). For `UITableViewHeaderFooterView` subclasses, use `registerClass:forHeaderFooterViewReuseIdentifier:` + `dequeueReusable…` rather than the legacy XIB nib registration.
- **Reactive glue.** ReactiveObjC (`@weakify`/`@strongify`, RACSignals) is used in places, but the dominant cross-module mechanism is **`NSNotificationCenter` with names defined in `BOOK_EVENT.h`** (e.g. `NOTIFICATION_BOOK_ADD`, `SYNCED_DATA_COMPLETE`, `MINE_TOKEN_EXPIRED`, `HOME_CELL_CLICK`). When adding a cross-screen event, define the constant there rather than inventing an inline string.
- **Networking.** Always go through `AFNManager POST:params:complete:`. It auto-injects `Authorization`, persists a refreshed token from response headers via `UserInfo`, and posts `MINE_TOKEN_EXPIRED` on `result.code == TOKEN_EXPIRED`. Endpoints belong in `NSString+API.h` as `Request(@"/path")` macros.
- **Auth & session.** `UserInfo` (singleton) holds login state and the `Authorization` token. Callers gate features with `[UserInfo isLogin]` and present `LoginController` when false. Face ID gating on app launch is keyed off the `PIN_SETTING_FACE_ID` `NSUserDefaults` flag and routed through `LAContextManager`.
- **Navigation chrome.** `HBDNavigationBar` + `KMNavigationBarTransition` are integrated; controllers toggle nav bar visibility with `self.hbd_barHidden = YES;` rather than the system API. `BaseNavigationController` is the standard nav stack.
- **Crash reporting.** Bugly is initialized in `AppDelegate` with app id `0025184dd7`.

## Working With This Codebase

- Objective-C only — no Swift sources are expected. New files use `.h`/`.m` and follow the `#pragma mark - 声明 / 实现` section pattern seen across modules.
- When adding a controller/model/category that other modules will reference, register it in `Common.h` under the matching `// =====` section. Failing to do so produces "unknown receiver" errors that look like missing imports but are actually a missing PCH entry.
- The widget target (`BookMonth`) does **not** see the main target's PCH — duplicate imports in `BookMonth/KKPrefixHeader.pch` if you need shared categories there.
- README and `.cursorrules` describe many TODOs and aspirational features (night mode, i18n, AI bill analysis, Siri shortcuts) — these are not yet implemented; do not assume the supporting infrastructure exists.
