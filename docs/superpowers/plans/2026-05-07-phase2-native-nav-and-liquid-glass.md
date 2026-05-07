# Phase 2 Native Navigation & Liquid Glass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace HBDNavigationBar with the system `UINavigationController` + `UINavigationBarAppearance`, drop the unused `KMNavigationBarTransition` Pod, and reach iOS 26 Liquid Glass compatibility while preserving the project's solid green brand chrome.

**Architecture:** Three independent commits on the `phase2-native-nav-and-liquid-glass` branch. Commit 1 plants the new infrastructure (appearance config + `prefersNavigationBarHidden` property + `self.title`) without removing anything — both old and new code coexist with no behavioural change. Commit 2 atomically swaps `BaseNavigationController`'s parent class from `HBDNavigationController` to `UINavigationController` and removes all `hbd_*` / `setNavTitle:` / customView-bar-button code from 24 controllers. Commit 3 deletes the now-unused HBD and KM Pods plus their Podfile patch hook.

**Tech Stack:** Objective-C, CocoaPods 1.11.3, Xcode 16+ / iOS 26 SDK, deployment target iOS 15.6, system `UINavigationController` / `UINavigationBarAppearance` / `UIBarButtonItem`, `UIBarButtonItemAppearance`.

**Spec:** `docs/superpowers/specs/2026-05-07-phase2-native-nav-and-liquid-glass-design.md` — all design decisions live there. This plan is the executable form.

**No automated tests.** Validation is manual regression as defined in the spec §6; each task ends only after the corresponding regression has passed.

**Pre-existing build caveat (carried over from Phase 1).** The `BookMonth` widget extension target has a long-standing header-search-path bug (`<MJExtension/MJExtension.h>` not found at compile time). This is NOT in scope. "Build succeeds" means **the `bookkeeping` (main app) target compiles with zero errors**, verified by:

```bash
xcodebuild ... build 2>&1 | grep -E "error:" | grep "in target 'bookkeeping' from project"
```
Expected: empty output. BookMonth-target errors are tolerated.

---

## File Structure

Phase 2 modifies existing files only — no new files are created. Modified surface:

| File | Role |
|---|---|
| `bookkeeping/bookkeeping/Classes/AppDelegate/AppDelegate.m` | Owner of `systemConfig` — host the global `UINavigationBarAppearance` |
| `bookkeeping/bookkeeping/Classes/Base/controller/BaseNavigationController.h` | Parent-class declaration |
| `bookkeeping/bookkeeping/Classes/Base/controller/BaseNavigationController.m` | Parent-class implementation |
| `bookkeeping/bookkeeping/Classes/Base/controller/BaseViewController.h` | Public API of the controller base |
| `bookkeeping/bookkeeping/Classes/Base/controller/BaseViewController.m` | Implementation of the controller base |
| `bookkeeping/bookkeeping/Common.h` | Umbrella header — drop HBD imports |
| `bookkeeping/Podfile` | Pod removal + patch-hook removal |
| 10 hidden-bar controllers | Each: `hbd_barHidden = YES` → `prefersNavigationBarHidden = YES` |
| 14 visible-bar controllers | Each: drop `hbd_*` lines and `setNavTitle:`, set `self.title`; some get system bar items |

---

## Pre-flight

Run once at the start. Working directory for everything below is `/Users/vancexin/repository/bookkeeping-iOS`.

- [ ] **Step P.1: Confirm we're on the right branch**

Run:
```bash
git branch --show-current
```
Expected: `phase2-native-nav-and-liquid-glass`. If on `master`, stop — branch off first.

- [ ] **Step P.2: Confirm clean working tree**

Run:
```bash
git status --short
```
Expected: empty output.

- [ ] **Step P.3: Confirm spec is committed on this branch**

Run:
```bash
git log --oneline -5 docs/superpowers/specs/2026-05-07-phase2-native-nav-and-liquid-glass-design.md
```
Expected: shows `3731b35 docs: phase 2 native navigation & liquid glass design spec`.

- [ ] **Step P.4: Snapshot baseline pod count**

Run:
```bash
grep -c "^[[:space:]]*pod " bookkeeping/Podfile
```
Expected: `16` (Phase 1 final state). After Commit 3 it should drop to `14`.

- [ ] **Step P.5: Snapshot baseline build**

Run:
```bash
xcodebuild -workspace bookkeeping/bookkeeping.xcworkspace \
           -scheme bookkeeping \
           -configuration Debug \
           -sdk iphonesimulator \
           -destination 'generic/platform=iOS Simulator' \
           build 2>&1 | grep -E "error:" | grep "in target 'bookkeeping' from project"
```
Expected: empty output. (Confirms we start from a green build.)

---

## Task 1: Commit 1 — Seed UINavigationBarAppearance + hidden-bar property

**Goal:** Plant new infrastructure with **zero behavioural change**. HBD remains the parent class and continues to render bars; new code lives alongside the old.

**Files:**
- Modify: `bookkeeping/bookkeeping/Classes/AppDelegate/AppDelegate.m` (`systemConfig` body)
- Modify: `bookkeeping/bookkeeping/Classes/Base/controller/BaseViewController.h` (add property)
- Modify: `bookkeeping/bookkeeping/Classes/Base/controller/BaseViewController.m` (add `viewDidLoad` line + `viewWillAppear:` line)
- Modify: 10 hidden-bar controllers (one new line each)
- Modify: 14 visible-bar controllers (one new line each)

### Step 1.1: Replace `AppDelegate.systemConfig` body

Open `bookkeeping/bookkeeping/Classes/AppDelegate/AppDelegate.m`. Find:

```objc
// 配置
- (void)systemConfig {
    [[UITextField appearance] setTintColor:kColor_Main_Color];
    // 设置导航栏按钮颜色
    [[UINavigationBar appearance] setTintColor:UIColor.whiteColor];
}
```

Replace with:

```objc
// 配置
- (void)systemConfig {
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = kColor_Main_Color;
    appearance.shadowColor = nil;                       // drop the bottom hairline
    appearance.titleTextAttributes = @{
        NSForegroundColorAttributeName: kColor_Text_White,
        NSFontAttributeName: [UIFont systemFontOfSize:AdjustFont(14)]
    };

    // Branded back-chevron tinted white via template rendering
    UIImage *chevron = [[UIImage imageNamed:@"nav_back_n"]
                        imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [appearance setBackIndicatorImage:chevron transitionMaskImage:chevron];

    // Bar item text styling (white, 14pt scaled)
    UIBarButtonItemAppearance *itemAppearance = [[UIBarButtonItemAppearance alloc] init];
    itemAppearance.normal.titleTextAttributes = @{
        NSForegroundColorAttributeName: kColor_Text_White,
        NSFontAttributeName: [UIFont systemFontOfSize:AdjustFont(14)]
    };
    appearance.buttonAppearance     = itemAppearance;
    appearance.backButtonAppearance = itemAppearance;
    appearance.doneButtonAppearance = itemAppearance;

    [[UINavigationBar appearance] setStandardAppearance:appearance];
    [[UINavigationBar appearance] setScrollEdgeAppearance:appearance];
    [[UINavigationBar appearance] setCompactAppearance:appearance];
    [[UINavigationBar appearance] setTintColor:kColor_Text_White];

    [[UITextField appearance] setTintColor:kColor_Main_Color];
}
```

The Phase 1 `setTintColor:UIColor.whiteColor` line is replaced by `setTintColor:kColor_Text_White` (same value, project macro).

While HBD is still parent of `BaseNavigationController`, HBD's own per-instance bar rendering will dominate. This appearance config is dormant for now and activates atomically when Commit 2 swaps the parent class.

- [ ] **Step 1.2: Add `prefersNavigationBarHidden` property to `BaseViewController.h`**

Open `bookkeeping/bookkeeping/Classes/Base/controller/BaseViewController.h`. Find:

```objc
// 是否允许侧滑返回
@property (nonatomic, assign, getter=isAllowBack) BOOL allowPanBack;
```

Replace with:

```objc
// 是否允许侧滑返回
@property (nonatomic, assign, getter=isAllowBack) BOOL allowPanBack;
// Phase 2 native-nav contract: subclasses set this in viewDidLoad to hide the
// navigation bar on the page. See BaseViewController.viewWillAppear:.
@property (nonatomic, assign) BOOL prefersNavigationBarHidden;
```

- [ ] **Step 1.3: Add `backButtonTitle` line to `BaseViewController.viewDidLoad`**

Open `bookkeeping/bookkeeping/Classes/Base/controller/BaseViewController.m`. Find:

```objc
- (void)viewDidLoad {
    [super viewDidLoad];
//    [self.navigationController setJz_navigationBarTransitionStyle:JZNavigationBarTransitionStyleSystem];
    [self.navigationController.interactivePopGestureRecognizer setEnabled:YES];
    [self.view setBackgroundColor:kColor_BG];
    [self initUI];
}
```

Replace with:

```objc
- (void)viewDidLoad {
    [super viewDidLoad];
//    [self.navigationController setJz_navigationBarTransitionStyle:JZNavigationBarTransitionStyleSystem];
    [self.navigationController.interactivePopGestureRecognizer setEnabled:YES];
    [self.view setBackgroundColor:kColor_BG];
    [self initUI];
    self.navigationItem.backButtonTitle = @"返回";
}
```

(`backButtonTitle` controls the text shown on the *next* pushed VC's system back button. Setting it on every page is harmless; it just inherits the label of whoever pushed.)

- [ ] **Step 1.4: Add `setNavigationBarHidden:` line to `BaseViewController.viewWillAppear:`**

In the same file, find:

```objc
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self hideNavigationBarLine];
    // iOS 26+ 把 BarButtonItem / 默认 back button 渲染成浮动的圆形玻璃按钮，
    // 即使 HBD 把导航条隐藏了，这些浮动按钮仍会出现，挡住页面内自己布的按钮，
    // 而且点击系统默认 back button 会与 HBDNavigationController 不兼容直接闪退。
    // 所以隐藏导航条的页面这里把所有可能的 bar 按钮（左、右、默认 back）一并清掉。
    if (self.hbd_barHidden) {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = nil;
        self.navigationItem.hidesBackButton = YES;
    }
}
```

Replace with:

```objc
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self hideNavigationBarLine];
    // iOS 26+ 把 BarButtonItem / 默认 back button 渲染成浮动的圆形玻璃按钮，
    // 即使 HBD 把导航条隐藏了，这些浮动按钮仍会出现，挡住页面内自己布的按钮，
    // 而且点击系统默认 back button 会与 HBDNavigationController 不兼容直接闪退。
    // 所以隐藏导航条的页面这里把所有可能的 bar 按钮（左、右、默认 back）一并清掉。
    if (self.hbd_barHidden) {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = nil;
        self.navigationItem.hidesBackButton = YES;
    }
    // Phase 2: native hide/show; runs in parallel with HBD's hbd_barHidden,
    // both flag the same intent. After Commit 2 the HBD branch above is gone.
    [self.navigationController setNavigationBarHidden:self.prefersNavigationBarHidden
                                             animated:animated];
}
```

- [ ] **Step 1.5: Add `prefersNavigationBarHidden = YES` to 10 hidden-bar controllers**

For each of the 10 controllers below, locate the line `self.hbd_barHidden = YES;` inside `viewDidLoad` and add a new line `self.prefersNavigationBarHidden = YES;` immediately after it. **Do not remove the `hbd_barHidden` line.** Both run in parallel.

The exact replacement for each file:

`bookkeeping/bookkeeping/Classes/Modules/Home/Controller/HomeController.m`

```diff
     self.hbd_barHidden = YES;
+    self.prefersNavigationBarHidden = YES;
```

`bookkeeping/bookkeeping/Classes/Modules/Me/Controller/MineController.m`

```diff
     self.hbd_barHidden = YES;
+    self.prefersNavigationBarHidden = YES;
```

`bookkeeping/bookkeeping/Classes/Modules/Chart/Controller/ChartController.m`

```diff
     self.hbd_barHidden = YES;
+    self.prefersNavigationBarHidden = YES;
```

`bookkeeping/bookkeeping/Classes/Modules/Book/Controller/BookController.m`

```diff
     self.hbd_barHidden = YES;
+    self.prefersNavigationBarHidden = YES;
```

`bookkeeping/bookkeeping/Classes/Modules/Verify/VerifyController.m`

```diff
     self.hbd_barHidden = YES;
+    self.prefersNavigationBarHidden = YES;
```

`bookkeeping/bookkeeping/Classes/Modules/Search/Controller/SearchViewController.m`

```diff
     self.hbd_barHidden = YES;
+    self.prefersNavigationBarHidden = YES;
```

`bookkeeping/bookkeeping/Classes/Modules/Detail/Controller/BookDetailController.m`

```diff
     self.hbd_barHidden = YES;
+    self.prefersNavigationBarHidden = YES;
```

`bookkeeping/bookkeeping/Classes/Modules/Login/Controller/LoginController.m`

```diff
     self.hbd_barHidden = YES;
+    self.prefersNavigationBarHidden = YES;
```

`bookkeeping/bookkeeping/Classes/Modules/Login/Controller/PasswordLoginController1.m`

```diff
     self.hbd_barHidden = YES;
+    self.prefersNavigationBarHidden = YES;
```

`bookkeeping/bookkeeping/Classes/Modules/Login/Controller/PasswordLoginController2.m`

```diff
     self.hbd_barHidden = YES;
+    self.prefersNavigationBarHidden = YES;
```

Verify all 10 took:
```bash
grep -rln "self\.prefersNavigationBarHidden = YES" bookkeeping/bookkeeping/Classes/Modules | wc -l
```
Expected: `10`.

- [ ] **Step 1.6: Add `self.title = ...` to 14 visible-bar controllers**

For each visible-bar controller, locate the existing `[self setNavTitle:@"..."]` line (or in the dynamic case, the `setNavTitle:` call) inside `viewDidLoad` and add a `self.title = @"...";` line immediately above it with the same string. **Do not remove the `setNavTitle:` line.**

`bookkeeping/bookkeeping/Classes/Modules/Bill/Controller/BillController.m`

```diff
+    self.title = @"账单";
     [self setNavTitle:@"账单"];
```

`bookkeeping/bookkeeping/Classes/Modules/Password/Controller/PasswordController.m`

```diff
+    self.title = @"修改密码";
     [self setNavTitle:@"修改密码"];
```

`bookkeeping/bookkeeping/Classes/Modules/Category/Controller/CAController.m`

```diff
+    self.title = @"类别设置";
     [self setNavTitle:@"类别设置"];
```

`bookkeeping/bookkeeping/Classes/Modules/WebView/WebViewController.m`

```diff
+    self.title = @"帮助";
     [self setNavTitle:@"帮助"];
```

`bookkeeping/bookkeeping/Classes/Modules/Feedback/FeedbackController.m`

```diff
+    self.title = @"反馈";
     [self setNavTitle:@"反馈"];
```

`bookkeeping/bookkeeping/Classes/Modules/About/Controller/AboutController.m`

```diff
+    self.title = @"关于";
     [self setNavTitle:@"关于"];
```

`bookkeeping/bookkeeping/Classes/Modules/About/Controller/DeleteAccountController.m`

```diff
+    self.title = @"删除账号";
     [self setNavTitle:@"删除账号"];
```

`bookkeeping/bookkeeping/Classes/Modules/Timing/Controller/TimeRemindController.m`

```diff
+    self.title = @"定时提醒";
     [self setNavTitle:@"定时提醒"];
```

`bookkeeping/bookkeeping/Classes/Modules/Info/Controller/InfoController.m`

```diff
+    self.title = @"个人信息";
     [self setNavTitle:@"个人信息"];
```

`bookkeeping/bookkeeping/Classes/Modules/AddCategory/Controller/ACAController.m`

```diff
+    self.title = @"添加类别";
     [self setNavTitle:@"添加类别"];
```

`bookkeeping/bookkeeping/Classes/Modules/Common/Controller/AgreementWebViewController.m`

```diff
+    self.title = self.type == AgreementTypeUserAgreement ? @"用户协议" : @"隐私政策";
     [self setNavTitle:self.type == AgreementTypeUserAgreement ? @"用户协议" : @"隐私政策"];
```

`bookkeeping/bookkeeping/Classes/Modules/Register/Controller/RegisterController.m` — RegisterController computes its title via a `({...})` block. Wrap the value once and reuse:

Find:
```objc
    [self setNavTitle:({
        // ... existing computation that returns NSString ...
    })];
```

Replace with:
```objc
    NSString *registerTitle = ({
        // ... same existing computation that returns NSString ...
    });
    self.title = registerTitle;
    [self setNavTitle:registerTitle];
```

(Read the existing block contents and place them inside the `registerTitle` initialiser literally; do not modify the computation logic.)

`bookkeeping/bookkeeping/Classes/Modules/Export/ExportController.m`

```diff
+    self.title = @"导出数据";
     [self setNavTitle:@"导出数据"];
```

`bookkeeping/bookkeeping/Classes/Modules/Share/Controller/ShareController.m`

```diff
+    self.title = @"分享";
     [self setNavTitle:@"分享"];
```

Verify all 14 added a `self.title =` line:
```bash
grep -rln "^[[:space:]]*self\.title = " bookkeeping/bookkeeping/Classes/Modules | wc -l
```
Expected: `14`.

- [ ] **Step 1.7: Build verification**

Run:
```bash
xcodebuild -workspace bookkeeping/bookkeeping.xcworkspace \
           -scheme bookkeeping \
           -configuration Debug \
           -sdk iphonesimulator \
           -destination 'generic/platform=iOS Simulator' \
           build 2>&1 | grep -E "error:" | grep "in target 'bookkeeping' from project"
```
Expected: empty output. If anything fails, the most likely cause is a typo in one of the 24 controller edits — re-check.

- [ ] **Step 1.8: Smoke test**

Cmd+R in Xcode, launch the app in the simulator. Confirm:
1. App launches normally to home or login.
2. Visit one hidden-bar page (Login screen).
3. Visit one visible-bar page (Mine → 个人信息).
4. Both pages render exactly as before — Commit 1 is no-op visually because HBD still rules.

If anything is visibly different, stop. Investigate.

- [ ] **Step 1.9: Commit**

```bash
git add bookkeeping/bookkeeping/Classes/AppDelegate/AppDelegate.m \
        bookkeeping/bookkeeping/Classes/Base/controller/BaseViewController.h \
        bookkeeping/bookkeeping/Classes/Base/controller/BaseViewController.m \
        bookkeeping/bookkeeping/Classes/Modules
git commit -m "feat(nav): seed UINavigationBarAppearance + hidden-bar property"
```

Verify: `git status --short` is empty.

---

## Task 2: Commit 2 — Switch to native UINavigationController

**Goal:** Atomic cutover. After this commit, HBD is no longer the parent of `BaseNavigationController`; all bar rendering goes through the appearance pipeline planted in Commit 1; all 24 controllers use the new APIs only.

**Files:**
- Modify: `bookkeeping/bookkeeping/Classes/Base/controller/BaseNavigationController.h`
- Modify: `bookkeeping/bookkeeping/Classes/Base/controller/BaseNavigationController.m`
- Modify: `bookkeeping/bookkeeping/Classes/Base/controller/BaseViewController.h`
- Modify: `bookkeeping/bookkeeping/Classes/Base/controller/BaseViewController.m`
- Modify: `bookkeeping/bookkeeping/Common.h`
- Modify: 24 controllers (10 hidden-bar simple removes; 14 visible-bar removes; 4 special bar buttons; 1 dead-code cleanup)

- [ ] **Step 2.1: Switch `BaseNavigationController` parent class**

Open `bookkeeping/bookkeeping/Classes/Base/controller/BaseNavigationController.h`.

Find any current declaration like `@interface BaseNavigationController : HBDNavigationController` and replace with:

```objc
@interface BaseNavigationController : UINavigationController
```

Also remove any `#import "HBDNavigationController.h"` or similar HBD imports from this header if present.

Verify:
```bash
grep -n "HBD" bookkeeping/bookkeeping/Classes/Base/controller/BaseNavigationController.h
```
Expected: empty output.

- [ ] **Step 2.2: Clean `BaseNavigationController.m`**

Open `bookkeeping/bookkeeping/Classes/Base/controller/BaseNavigationController.m`. The Phase-1-simplified `pushViewController:animated:` is already in place. Just remove the dead commented `jz_navigationBarTransitionStyle` line in `+ initWithRootViewController:` (Q6 of resolved defaults).

Find:
```objc
+ (instancetype)initWithRootViewController:(UIViewController *)vc {
    BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController:vc];
//    nav.jz_navigationBarTransitionStyle = JZNavigationBarTransitionStyleSystem;
    return nav;
}
```

Replace with:

```objc
+ (instancetype)initWithRootViewController:(UIViewController *)vc {
    BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController:vc];
    return nav;
}
```

Verify the file no longer references HBD/KM:
```bash
grep -n "HBD\|jz_\|km_\|AsyncDisplayKit" bookkeeping/bookkeeping/Classes/Base/controller/BaseNavigationController.m
```
Expected: empty output. (AsyncDisplayKit was already cleared in Phase 1.)

- [ ] **Step 2.3: Trim `BaseViewController.h` API surface**

Open `bookkeeping/bookkeeping/Classes/Base/controller/BaseViewController.h`. Replace the entire file with:

```objc
//
//  BaseViewController.h
//  iOS
//
//  Created by RY on 2018/3/19.
//  Copyright © 2018年 KK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseView.h"

@interface BaseViewController : UIViewController

// 是否允许侧滑返回
@property (nonatomic, assign, getter=isAllowBack) BOOL allowPanBack;

// Phase 2 native-nav contract: subclasses set this in viewDidLoad to hide the
// navigation bar on the page. See BaseViewController.viewWillAppear:.
@property (nonatomic, assign) BOOL prefersNavigationBarHidden;

// 导航栏
@property (nonatomic, strong) UIColor *navColor;

@end
```

Removed:
- `navTitle` property (use `self.title` directly)
- `leftButton` / `rightButton` properties (use `self.navigationItem.leftBarButtonItem` / `rightBarButtonItem`)
- `leftButtonClick` / `rightButtonClick` method declarations (now per-controller selectors)
- `hideNavigationBarLine` / `showNavigationBarLine` (the appearance config kills the hairline globally)
- `initUI` (no longer hooked)

- [ ] **Step 2.4: Trim `BaseViewController.m`**

Open `bookkeeping/bookkeeping/Classes/Base/controller/BaseViewController.m`. Replace the entire file contents with:

```objc
//
//  BaseViewController.m
//  iOS
//
//  Created by RY on 2018/3/19.
//  Copyright © 2018年 KK. All rights reserved.
//

#import "BaseViewController.h"

#pragma mark - 实现
@implementation BaseViewController

#pragma mark - 初始化
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController.interactivePopGestureRecognizer setEnabled:YES];
    [self.view setBackgroundColor:kColor_BG];
    self.navigationItem.backButtonTitle = @"返回";
}

#pragma mark - 系统
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:self.prefersNavigationBarHidden
                                             animated:animated];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
```

Removed (per spec §3.3):
- `setNavTitle:` setter
- `leftButtonClick` / `rightButtonClick` (default selectors that subclasses overrode)
- `setLeftBtn` / `setRightBtn` (built the customView bar items)
- `initUI` (called the two helpers above)
- `hideNavigationBarLine` / `showNavigationBarLine` (used `setShadowImage:`)
- The `if (self.hbd_barHidden) { ... hidesBackButton = YES; ... }` branch (Phase 1 mitigation, no longer needed because native `setNavigationBarHidden:` removes the whole bar cleanly)

The class no longer references `HBDNavigationController.h`. `viewDidLoad`/`viewWillAppear:`/`dealloc` are the entire base.

- [ ] **Step 2.5: Drop HBD import from `Common.h`**

Open `bookkeeping/bookkeeping/Common.h`. Find:

```objc
#import "UIViewController+HBD.h"
```

Delete that line entirely.

Verify:
```bash
grep -n "HBD" bookkeeping/bookkeeping/Common.h
```
Expected: empty output.

- [ ] **Step 2.6: Strip `hbd_*` and `setNavTitle:` from 10 hidden-bar controllers**

For each of the 10 hidden-bar controllers, remove the now-redundant `self.hbd_barHidden = YES;` line (the new `self.prefersNavigationBarHidden = YES;` is doing the work). Keep everything else.

The replacement for each file:

`bookkeeping/bookkeeping/Classes/Modules/Home/Controller/HomeController.m`

```diff
-    self.hbd_barHidden = YES;
     self.prefersNavigationBarHidden = YES;
```

Apply the same one-line diff in:
- `bookkeeping/bookkeeping/Classes/Modules/Me/Controller/MineController.m`
- `bookkeeping/bookkeeping/Classes/Modules/Chart/Controller/ChartController.m`
- `bookkeeping/bookkeeping/Classes/Modules/Book/Controller/BookController.m`
- `bookkeeping/bookkeeping/Classes/Modules/Verify/VerifyController.m`
- `bookkeeping/bookkeeping/Classes/Modules/Search/Controller/SearchViewController.m`
- `bookkeeping/bookkeeping/Classes/Modules/Detail/Controller/BookDetailController.m`
- `bookkeeping/bookkeeping/Classes/Modules/Login/Controller/LoginController.m`
- `bookkeeping/bookkeeping/Classes/Modules/Login/Controller/PasswordLoginController1.m`
- `bookkeeping/bookkeeping/Classes/Modules/Login/Controller/PasswordLoginController2.m`

`BookDetailController.m` additionally has a dead `[self.rightButton setHidden:YES];` line — locate and delete that line (Q4 of resolved defaults).

Verify the count:
```bash
grep -rln "self\.hbd_barHidden = YES" bookkeeping/bookkeeping/Classes/Modules
```
Expected: empty output (no controller still references the hidden=YES path).

- [ ] **Step 2.7: Strip `hbd_*` and `setNavTitle:` from 11 simple visible-bar controllers**

11 of the 14 visible-bar controllers have only the simple three-line removal (no special right/left button work). For each:

```diff
-    self.hbd_barHidden = NO;
-    self.hbd_barTintColor = kColor_Main_Color;
     self.title = @"<existing>";
-    [self setNavTitle:@"<existing>"];
```

Apply this pattern in:
- `bookkeeping/bookkeeping/Classes/Modules/Password/Controller/PasswordController.m`
- `bookkeeping/bookkeeping/Classes/Modules/Feedback/FeedbackController.m`
- `bookkeeping/bookkeeping/Classes/Modules/About/Controller/AboutController.m`
- `bookkeeping/bookkeeping/Classes/Modules/About/Controller/DeleteAccountController.m`
- `bookkeeping/bookkeeping/Classes/Modules/Timing/Controller/TimeRemindController.m`
- `bookkeeping/bookkeeping/Classes/Modules/Info/Controller/InfoController.m`
- `bookkeeping/bookkeeping/Classes/Modules/Common/Controller/AgreementWebViewController.m`
- `bookkeeping/bookkeeping/Classes/Modules/Export/ExportController.m`
- `bookkeeping/bookkeeping/Classes/Modules/Share/Controller/ShareController.m`

For `bookkeeping/bookkeeping/Classes/Modules/Register/Controller/RegisterController.m`, where Step 1.6 introduced a `registerTitle` local: remove the now-redundant `[self setNavTitle:registerTitle];` line, leaving only `self.title = registerTitle;`.

For `bookkeeping/bookkeeping/Classes/Modules/WebView/WebViewController.m`, do the same three-line removal here (the left-button conversion is Step 2.10 below; do not touch that here yet).

Verify:
```bash
grep -rln "self\.hbd_barTintColor\|setNavTitle:" bookkeeping/bookkeeping/Classes/Modules
```
Expected: 3 files left to handle (CAController, ACAController, BillController). Continue.

- [ ] **Step 2.8: Convert `CAController` right button to system Done item**

`CAController` does **not** override `rightButtonClick` — it inherited the empty implementation from `BaseViewController`, so the "完成" button currently does nothing on tap. After Step 2.4 the inherited stub is gone; we need to preserve the existing no-op behaviour by adding an explicit stub.

Open `bookkeeping/bookkeeping/Classes/Modules/Category/Controller/CAController.m`. Find the block in `viewDidLoad` containing:

```objc
    self.hbd_barHidden = NO;
    self.hbd_barTintColor = kColor_Main_Color;
    self.title = @"类别设置";
    [self setNavTitle:@"类别设置"];
    [self.rightButton setTitle:@"完成" forState:UIControlStateNormal];
    [self.rightButton setTitle:@"完成" forState:UIControlStateHighlighted];
```

(There may be additional `self.rightButton` configuration lines — read the surrounding context.)

Replace the entire block (everything that touches `self.hbd_*`, `setNavTitle:`, and `self.rightButton`) with:

```objc
    self.title = @"类别设置";
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"完成"
                                         style:UIBarButtonItemStyleDone
                                        target:self
                                        action:@selector(rightButtonClick)];
```

Add this no-op stub anywhere inside the `@implementation` (e.g., right above `@end`):

```objc
// Preserve the inherited no-op from BaseViewController. The 完成 right button
// was historically wired to this empty selector; not changing behaviour here.
- (void)rightButtonClick {
}
```

Verify:
```bash
grep -n "^- (void)rightButtonClick" bookkeeping/bookkeeping/Classes/Modules/Category/Controller/CAController.m
```
Expected: one match.

- [ ] **Step 2.9: Convert `ACAController` right button to system Done item**

Open `bookkeeping/bookkeeping/Classes/Modules/AddCategory/Controller/ACAController.m`. Find:

```objc
    self.hbd_barHidden = NO;
    self.hbd_barTintColor = kColor_Main_Color;
    self.title = @"添加类别";
    [self setNavTitle:@"添加类别"];
    [self.rightButton setTitle:@"完成" forState:UIControlStateNormal];
    [self.rightButton setTitle:@"完成" forState:UIControlStateHighlighted];
    [self.rightButton setHidden:NO];
    [self.rightButton setTitleColor:kColor_Text_White forState:UIControlStateNormal];
    [self.rightButton setTitleColor:kColor_Text_Gary forState:UIControlStateHighlighted];
```

Replace with:

```objc
    self.title = @"添加类别";
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"完成"
                                         style:UIBarButtonItemStyleDone
                                        target:self
                                        action:@selector(rightButtonClick)];
```

(Title text colour comes from the global `UIBarButtonItemAppearance` planted in Step 1.1; per-state colour overrides are not preserved — system style handles disabled/highlighted automatically.)

Verify `rightButtonClick` exists in this file (same check as Step 2.8).

- [ ] **Step 2.10: Convert `WebViewController` left button to system bar item**

`WebViewController` currently has TWO competing left-button code paths:
1. Lines 44-45: re-targets the inherited `self.leftButton` (customView from `setLeftBtn`) — dead after `setupBackButton` runs.
2. Lines 55-70: `setupBackButton` creates a custom `UIButton` with a hand-tinted white chevron and sets it as `leftBarButtonItem`.
3. Lines 72-95: `imageWithTintColor:image:` helper used only by `setupBackButton`.

After Step 2.4 there is no `self.leftButton` to re-target. Replace all three with a single system bar item using template rendering (the global tintColor white from Step 1.1 applies automatically — no manual tinting helper needed).

Open `bookkeeping/bookkeeping/Classes/Modules/WebView/WebViewController.m`.

Edit A — replace the `viewDidLoad` block. Find:

```objc
- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = NO;
    self.hbd_barTintColor = kColor_Main_Color;
    [self setNavTitle:@"帮助"];

    // 使用父类方法设置返回按钮，而不是自定义
    [self setupBackButton];

    // 覆盖左边按钮的点击事件
    [self.leftButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.leftButton addTarget:self action:@selector(handleBackAction) forControlEvents:UIControlEventTouchUpInside];

    [self web];
    [self myProgressView];
    if (_url) {
        [self.web loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_url]]];
    }
}
```

Replace with:

```objc
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"帮助";

    // Override system back: tap routes through WKWebView history first;
    // only pops the controller when web history is empty. Template image
    // inherits the global white tint from UINavigationBar.appearance.
    UIImage *backImage = [[UIImage imageNamed:@"nav_back_n"]
                          imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithImage:backImage
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(handleBackAction)];

    [self web];
    [self myProgressView];
    if (_url) {
        [self.web loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_url]]];
    }
}
```

Edit B — delete the now-unused helper methods. Find and delete the entire `setupBackButton` method (the block starting `// 设置自定义返回按钮` / `- (void)setupBackButton {` and ending at its closing `}`). Find and delete the entire `imageWithTintColor:image:` method (the block starting `// 将图片染色的辅助方法` / `- (UIImage *)imageWithTintColor:(UIColor *)tintColor image:(UIImage *)image {` and ending at its closing `}`).

Do **not** touch `handleBackAction` (around line 98) — its body that walks WKWebView history then pops the controller is the contract being preserved.

Verify:
```bash
grep -n "setupBackButton\|imageWithTintColor:image:\|self\.leftButton" \
     bookkeeping/bookkeeping/Classes/Modules/WebView/WebViewController.m
```
Expected: empty output.

- [ ] **Step 2.11: Convert `BillController` composite year+arrow right button**

Open `bookkeeping/bookkeeping/Classes/Modules/Bill/Controller/BillController.m`. Find the block in `viewDidLoad` containing the year `UILabel` (tag 10) and arrow `UIImageView` setup, then the `self.rightButton` frame computation, then the `[self table]` call. The relevant block reads roughly:

```objc
    self.hbd_barHidden = NO;
    self.hbd_barTintColor = kColor_Main_Color;
    self.title = @"账单";
    [self setNavTitle:@"账单"];
    [self setDate:[NSDate date]];
    [self.rightButton setHidden:false];
    [self.rightButton addSubview:({
        NSDate *date = [NSDate date];
        NSString *year = [NSString stringWithFormat:@"%ld年", date.year];
        UIFont *font = [UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(14)];
        CGFloat width = [year sizeWithMaxSize:CGSizeMake(MAXFLOAT, 0) font:font].width;

        UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 44)];
        lab.text = year;
        lab.font = font;
        lab.textColor = kColor_Text_White;
        lab.textAlignment = NSTextAlignmentRight;
        lab.tag = 10;
        lab;
    })];
    [self.rightButton setFrame:CGRectMake(0, 0, [self.rightButton viewWithTag:10].width + 10, 44)];
    [self.rightButton addSubview:({
        CGFloat width = 10;
        UIImageView *image = [[UIImageView alloc] init];
        image.frame = CGRectMake(self.rightButton.width - width, 0, width, self.rightButton.height);
        image.image = [UIImage imageNamed:@"time_down"];
        image.contentMode = UIViewContentModeScaleAspectFit;
        image;
    })];
```

Replace the entire block with:

```objc
    self.title = @"账单";
    [self setDate:[NSDate date]];
    {
        // Composite year + arrow as the only customView right bar item — wrapped
        // in a plain UIView so the year label keeps its tag-10 lookup contract.
        NSDate *date = [NSDate date];
        NSString *year = [NSString stringWithFormat:@"%ld年", date.year];
        UIFont *font = [UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(14)];
        CGFloat labWidth = [year sizeWithMaxSize:CGSizeMake(MAXFLOAT, 0) font:font].width;
        CGFloat arrowWidth = 10;
        CGFloat totalWidth = labWidth + arrowWidth + 4;

        UIView *wrapper = [[UIView alloc] initWithFrame:CGRectMake(0, 0, totalWidth, 44)];

        UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, labWidth, 44)];
        lab.text = year;
        lab.font = font;
        lab.textColor = kColor_Text_White;
        lab.textAlignment = NSTextAlignmentRight;
        lab.tag = 10;
        [wrapper addSubview:lab];

        UIImageView *arrow = [[UIImageView alloc] initWithFrame:CGRectMake(totalWidth - arrowWidth, 0, arrowWidth, 44)];
        arrow.image = [UIImage imageNamed:@"time_down"];
        arrow.contentMode = UIViewContentModeScaleAspectFit;
        [wrapper addSubview:arrow];

        self.navigationItem.rightBarButtonItem =
            [[UIBarButtonItem alloc] initWithCustomView:wrapper];
    }
```

Then update `updateYearValue:` further down in the file. Find:

```objc
- (void)updateYearValue:(NSString *)selectValue {
    ...
    [(UILabel *)[self.rightButton viewWithTag:10] setText:[NSString stringWithFormat:@"%ld年", self.date.year]];
    ...
}
```

Replace `self.rightButton` with the new customView host:

```objc
    [(UILabel *)[self.navigationItem.rightBarButtonItem.customView viewWithTag:10]
        setText:[NSString stringWithFormat:@"%ld年", self.date.year]];
```

(The viewWithTag:10 lookup contract is preserved through the customView wrapper.)

Also remove `self.hbd_barHidden = NO;` and `self.hbd_barTintColor = kColor_Main_Color;` from the file if any remain (the block above already removed them). Verify:

```bash
grep -n "self\.hbd_\|setNavTitle:\|self\.rightButton" bookkeeping/bookkeeping/Classes/Modules/Bill/Controller/BillController.m
```
Expected: empty output.

- [ ] **Step 2.12: Sweep — confirm no `hbd_*` / `setNavTitle:` / `self.leftButton` / `self.rightButton` remains**

```bash
grep -rln "hbd_\|setNavTitle:" bookkeeping/bookkeeping/Classes/Modules bookkeeping/bookkeeping/Classes/Base
```
Expected: empty output.

```bash
grep -rln "self\.leftButton\b\|self\.rightButton\b" bookkeeping/bookkeeping/Classes/Modules bookkeeping/bookkeeping/Classes/Base
```
Expected: empty output.

If anything remains, fix it before proceeding — it indicates a missed step.

- [ ] **Step 2.13: Build verification**

```bash
xcodebuild -workspace bookkeeping/bookkeeping.xcworkspace \
           -scheme bookkeeping \
           -configuration Debug \
           -sdk iphonesimulator \
           -destination 'generic/platform=iOS Simulator' \
           build 2>&1 | grep -E "error:" | grep "in target 'bookkeeping' from project"
```
Expected: empty output. Common failure modes:
- "No visible @interface for ... declares the selector 'setNavTitle:'": leftover call site missed in Step 2.7 — grep again and fix.
- "Property 'leftButton' not found on object of type 'BaseViewController'": leftover `self.leftButton` reference — grep again.
- "Use of undeclared identifier 'rightButtonClick'": a controller used the inherited method via `target:self action:@selector(rightButtonClick)` but never overrode it. Inspect the controller and either implement `rightButtonClick` or change the `@selector` to whatever method the controller actually calls.

- [ ] **Step 2.14: Manual regression — hidden-bar group**

For each of the 10 hidden-bar controllers, perform the action and confirm the pass criterion. Stop on the first failure and capture the symptom (screenshot + console log) before moving on.

| Controller | Action | Pass criteria |
|---|---|---|
| `HomeController` | App launch | Top of screen has no leftover navigation chrome; in-page navigation subview renders correctly; account list scrolls |
| `MineController` | Tab/sidebar | Same |
| `ChartController` | Enter chart tab | Same |
| `BookController` | Tap "+" or invoke `kbook://month` | Own close button works |
| `VerifyController` | Login → SMS → enter code | Own close button works; no floating glass leftover |
| `SearchViewController` | Home → search | Own back works → pop never crashes |
| `BookDetailController` | Tap a booking row | Own back works |
| `LoginController` | Launch when logged out | Own close works |
| `PasswordLoginController1` | Login → 密码登录 | Own close works |
| `PasswordLoginController2` | Continue from PasswordLogin1 | Own close works |

- [ ] **Step 2.15: Manual regression — visible-bar group**

For each of the 14 visible-bar controllers:

| Controller | Path | Pass criteria |
|---|---|---|
| `BillController` | Home → month picker | Green bar + "账单" title (white) + composite year+arrow right (glass-wrapped on iOS 26 but tappable) |
| `PasswordController` | Info → 修改密码 | Green + "修改密码" + system back ("返回") |
| `CAController` | Info → 类别设置 | Green + "类别设置" + system Done "完成" → fires `rightButtonClick` |
| `WebViewController` | Info → 帮助 | Green + "帮助" + custom left chevron → `handleBackAction` (WKWebView history pop) |
| `FeedbackController` | Info → 反馈 | Green + "反馈" + system back |
| `AboutController` | Info → 关于 | Green + "关于" + system back |
| `DeleteAccountController` | Info → 删除账号 | Green + "删除账号" + system back |
| `TimeRemindController` | Info → 定时提醒 | Green + "定时提醒" + system back |
| `InfoController` | Mine → 个人信息 | Green + "个人信息" + system back |
| `ACAController` | 类别设置 → "+" | Green + "添加类别" + system Done "完成" |
| `RegisterController` | Login → 注册 | Green + dynamic title + system back |
| `AgreementWebViewController` | Login → 用户协议/隐私政策 | Green + correct title + system back |
| `ExportController` | Mine → 导出数据 | Green + "导出数据" + system back |
| `ShareController` | Entry | Green + "分享" + system back |

- [ ] **Step 2.16: Manual regression — cross-cutting**

- System edge-pop gesture: from any pushed visible-bar controller, swipe from left edge → pop succeeds, no crash.
- iOS 26 visual: bar items are glass capsules atop the opaque green bar; tap targets are accurate.
- When a child is pushed from a visible-bar parent, the system back button shows "返回" (left of chevron).
- Title font/colour: white, ≈14pt scaled — visually identical to pre-Phase-2.
- Hairline under the bar is gone (Phase 2 explicitly nulled `shadowColor`).
- All Phase 1 business regressions still pass: login, booking CRUD, charts, avatar upload, token expiry handling.

- [ ] **Step 2.17: Commit**

```bash
git add bookkeeping/bookkeeping/Classes/Base \
        bookkeeping/bookkeeping/Common.h \
        bookkeeping/bookkeeping/Classes/Modules
git status --short
```

Verify only files listed above (and their subtree) are staged. Then:

```bash
git commit -m "$(cat <<'EOF'
refactor(nav): switch to native UINavigationController

BaseNavigationController parent class flips from HBDNavigationController
to UINavigationController. Bar appearance is now driven entirely by the
UINavigationBarAppearance configuration planted in Commit 1.

Across 24 controllers:
  * hbd_barHidden / hbd_barTintColor assignments removed
  * setNavTitle: replaced by self.title (already added in Commit 1)
  * 4 customView bar items converted to system UIBarButtonItem
    (CAController + ACAController to Done; BillController year+arrow
    to initWithCustomView:; WebViewController left chevron to
    initWithImage: driving handleBackAction)

BaseViewController shrinks: leftButton/rightButton/setNavTitle:/initUI/
hideNavigationBarLine all removed; only viewDidLoad + viewWillAppear:
+ dealloc remain.

Common.h drops UIViewController+HBD.h. Phase 1's hbd_barHidden bar-item
cleanup branch is removed — native setNavigationBarHidden: handles
the hide path cleanly without iOS 26 floating-glass artefacts.

The HBDNavigationBar Pod itself is still on disk; Commit 3 removes it.
EOF
)"
```

Verify clean tree: `git status --short` is empty.

---

## Task 3: Commit 3 — Drop HBDNavigationBar and KMNavigationBarTransition pods

**Goal:** Pure dependency cleanup. No source change other than the Podfile.

**Files:**
- Modify: `bookkeeping/Podfile`

- [ ] **Step 3.1: Remove HBD and KM pod lines from Podfile**

Open `bookkeeping/Podfile`. Find:

```ruby
    pod 'KMNavigationBarTransition', '1.1.5'
    pod 'Bugly'
    pod 'HBDNavigationBar', '~> 1.9.5'
    pod 'ZLPhotoBrowser'
```

Replace with:

```ruby
    pod 'Bugly'
    pod 'ZLPhotoBrowser'
```

Verify:
```bash
grep -nE "HBDNavigationBar|KMNavigationBarTransition" bookkeeping/Podfile
```
Expected: empty output.

- [ ] **Step 3.2: Remove the HBD KVC `@try/@catch` patch hook**

In the same `Podfile`, find the entire block:

```ruby
  # 修复 HBDNavigationBar 1.9.5 在 iOS 26 上闪退（NSUnknownKeyException: contentView）
  # iOS 26 把 UINavigationBar 的 visualProvider 换成 Swift 类 _UINavigationBarVisualProviderModernIOSSwift，
  # 不再 KVC 兼容 contentView / titleButton。给两处 KVC 包 @try/@catch，失败时返回 nil（调用方有 nil 防护）。
  hbd_bar = File.join(installer.config.installation_root, 'Pods/HBDNavigationBar/HBDNavigationBar/Classes/HBDNavigationBar.m')
  if File.exist?(hbd_bar)
    original = File.read(hbd_bar)
    patched = original
      .gsub(
        'UIView *navigationBarContentView = [self valueForKeyPath:@"visualProvider.contentView"];',
        "UIView *navigationBarContentView = nil;\n    @try { navigationBarContentView = [self valueForKeyPath:@\"visualProvider.contentView\"]; } @catch (NSException *e) { return nil; }"
      )
      .gsub(
        'UIButton *titleButton = [subview valueForKeyPath:@"visualProvider.titleButton"];',
        "UIButton *titleButton = nil;\n            @try { titleButton = [subview valueForKeyPath:@\"visualProvider.titleButton\"]; } @catch (NSException *e) {}"
      )
    if patched != original
      File.chmod(0644, hbd_bar)
      File.write(hbd_bar, patched)
      Pod::UI.puts "[patch] HBDNavigationBar guarded KVC against iOS 26 visual provider".yellow
    end
  end
```

Delete it entirely, including any blank lines that surround it (so the `post_install` block ends cleanly).

Verify:
```bash
grep -nE "HBDNavigationBar|hbd_bar" bookkeeping/Podfile
```
Expected: empty output.

- [ ] **Step 3.3: Re-resolve Pods**

Run:
```bash
cd bookkeeping && pod install 2>&1 | tail -10
```

Expected output contains:
```
Removing HBDNavigationBar
Removing KMNavigationBarTransition
...
Pod installation complete! There are 14 dependencies from the Podfile and 14 total pods installed.
```

The `[patch] HBDNavigationBar guarded KVC ...` line should NOT appear (the patch hook is gone).

- [ ] **Step 3.4: Confirm Pod directories are gone**

```bash
ls -d bookkeeping/Pods/HBDNavigationBar bookkeeping/Pods/KMNavigationBarTransition 2>&1
```
Expected: two "No such file or directory" errors.

- [ ] **Step 3.5: Build verification**

```bash
xcodebuild -workspace bookkeeping/bookkeeping.xcworkspace \
           -scheme bookkeeping \
           -configuration Debug \
           -sdk iphonesimulator \
           -destination 'generic/platform=iOS Simulator' \
           build 2>&1 | grep -E "error:" | grep "in target 'bookkeeping' from project"
```
Expected: empty output. If you see "module 'HBDNavigationBar' not found" or similar, a stale `#import` was missed — grep:

```bash
grep -rln "HBDNavigationBar\|KMNavigationBarTransition\|UIViewController+HBD\|hbd_" bookkeeping/bookkeeping
```
and clean up.

- [ ] **Step 3.6: Smoke test**

Run the app in simulator. Pick any 3 hidden-bar pages (e.g. Home, Login, Search) and any 3 visible-bar pages (e.g. Info, About, Bill). Push and pop each. Visual + behaviour should match Commit 2 exactly.

- [ ] **Step 3.7: Commit**

```bash
git add bookkeeping/Podfile \
        bookkeeping/Podfile.lock \
        bookkeeping/Pods/Manifest.lock \
        bookkeeping/Pods/Pods.xcodeproj/project.pbxproj
git add -A bookkeeping/Pods/HBDNavigationBar bookkeeping/Pods/KMNavigationBarTransition 2>/dev/null
git add -A 'bookkeeping/Pods/Target Support Files/HBDNavigationBar' \
           'bookkeeping/Pods/Target Support Files/KMNavigationBarTransition' 2>/dev/null
git add 'bookkeeping/Pods/Target Support Files/Pods-bookkeeping'
git status --short | head -10
```

Verify the staged set includes:
- `M` Podfile, Podfile.lock, Manifest.lock, Pods.xcodeproj
- `D` for everything under `Pods/HBDNavigationBar/` and `Pods/KMNavigationBarTransition/`
- Possibly `M` for files under `Pods/Target Support Files/Pods-bookkeeping/` (frameworks list shrinks)

Then:

```bash
git commit -m "chore(nav): drop HBDNavigationBar and KMNavigationBarTransition pods"
```

Verify clean tree: `git status --short` is empty.

---

## Final verification

- [ ] **Step F.1: Pod count drops to 14**

```bash
grep -c "^[[:space:]]*pod " bookkeeping/Podfile
```
Expected: `14`.

- [ ] **Step F.2: Both Pod directories are gone**

```bash
ls -d bookkeeping/Pods/HBDNavigationBar bookkeeping/Pods/KMNavigationBarTransition 2>&1
```
Expected: two "No such file or directory" errors.

- [ ] **Step F.3: Source code has zero HBD/KM references**

```bash
grep -rln "HBDNavigationBar\|HBDNavigationController\|KMNavigationBarTransition\|UIViewController+HBD\|hbd_" bookkeeping/bookkeeping
```
Expected: empty output.

- [ ] **Step F.4: Phase 2 commit log**

```bash
git log --oneline -5
```
Expected: top-of-stack matches the three Phase 2 commits plus the spec commit:
```
<hash> chore(nav): drop HBDNavigationBar and KMNavigationBarTransition pods
<hash> refactor(nav): switch to native UINavigationController
<hash> feat(nav): seed UINavigationBarAppearance + hidden-bar property
3731b35 docs: phase 2 native navigation & liquid glass design spec
```

If everything above is green, Phase 2 is complete. The `finishing-a-development-branch` skill chooses the next step (merge to master / open a PR / keep as-is).

---

## Rollback procedures

Single-commit revert:
```bash
git revert <commit-hash>
cd bookkeeping && pod install   # only required if reverting Commit 3
```

Whole-phase rollback (do in reverse order):
```bash
git revert <commit-3-hash>
cd bookkeeping && pod install   # restores HBD + KM Pods + the KVC patch hook
git revert <commit-2-hash>
git revert <commit-1-hash>
```

After a full rollback the branch matches the Phase 1 final state on `master`. The `phase2-native-nav-and-liquid-glass` branch can then be discarded (`git branch -D phase2-native-nav-and-liquid-glass`) or kept for reference.
