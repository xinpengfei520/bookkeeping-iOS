# Phase 2 — Native Navigation & iOS 26 Liquid Glass

**Date:** 2026-05-07
**Status:** Approved (sections 1–6)
**Owner:** Xin Vance
**Branch:** `phase2-native-nav-and-liquid-glass` (split from `master` at `1929910`)
**Predecessor:** Phase 1 — `docs/superpowers/specs/2026-05-07-phase1-dependency-cleanup-design.md` (merged to `master`)

---

## 1. Background

Phase 1 dropped three abandoned third-party libraries (YYText, Texture, AFNetworking).
The fourth library on the original cleanup list — **HBDNavigationBar** — was deferred
to Phase 2 because navigation is woven through every screen and the work is intrinsically
tied to iOS 26's Liquid Glass adaptation.

A scope scan of the actual HBD usage surface produced a happy surprise:

| Property | Occurrences | Values |
|---|---|---|
| `hbd_barHidden` | 25 | `YES` (10 controllers) or `NO` (14 controllers) |
| `hbd_barTintColor` | 14 | always `kColor_Main_Color` (the brand green) |
| Other `hbd_*` | 0 | none used |

The project never adopted any of HBD's signature features (per-page transparency,
animated transitions, blur, custom shadow). It uses HBD only as a switchable hide/show
control plus a uniform green tint — both replaceable by `UINavigationBarAppearance`
in 5–10 lines.

`KMNavigationBarTransition` is in the Podfile but **completely unused** (the only
reference is a commented-out line in `BaseNavigationController.m`). It comes off
in the same cleanup.

iOS 26 introduces "Liquid Glass" — translucent navigation chrome with circular
floating bar buttons. This conflicts with the project's solid-green brand. The
user's chosen direction (Section 4 Q1 of brainstorming) is to **preserve the
solid green brand**: `configureWithOpaqueBackground` + `backgroundColor =
kColor_Main_Color` keeps the bar opaque even on iOS 26. Bar items themselves are
still wrapped by the system in glass capsules on iOS 26 — that part of Liquid
Glass cannot be opted out of and is accepted as a system-managed visual.

---

## 2. Scope

### In scope

1. **`BaseNavigationController`** parent class swap: `HBDNavigationController` → `UINavigationController`. Simplify `pushViewController:animated:` (drop HBD-aware branching done in Phase 1).
2. **Global `UINavigationBarAppearance`** in `AppDelegate.systemConfig`: opaque `kColor_Main_Color` background, white title text (`AdjustFont(14)`), white tint, white-text bar items, branded back-chevron template image.
3. **Hide/show contract**: replace `hbd_barHidden` with a self-owned `prefersNavigationBarHidden` BOOL on `BaseViewController`, hooked into `viewWillAppear:` via `[self.navigationController setNavigationBarHidden:animated:]`.
4. **Bar items normalised to system `UIBarButtonItem`**:
   - Left side defaults to system back; `backButtonTitle = @"返回"` set globally in `BaseViewController.viewDidLoad`.
   - Right buttons: `CAController` / `ACAController` ("完成") become `initWithTitle:style:UIBarButtonItemStyleDone`. `BillController`'s composite year+arrow stays as a customView wrapped by `initWithCustomView:` (the only customView remaining). `BookDetailController`'s rightButton manipulation is deleted (it was inside a hidden-bar page anyway).
   - WebView's `self.leftButton` override (which routes back to WKWebView history pop) becomes `initWithImage:style:target:action:` driving the existing `handleBackAction`.
5. **Title API**: replace 17 call sites of `setNavTitle:` with `self.title = @"..."`. Title styling comes from the global appearance.
6. **24 controllers updated**: remove all `hbd_*` assignments and now-redundant `setNavTitle:` / `leftButton` / `rightButton` manipulation.
7. **Pod removal**: `HBDNavigationBar` and `KMNavigationBarTransition`. Drop the HBD KVC `@try/@catch` patch hook from Podfile `post_install` (no longer has a target).
8. **`Common.h`**: drop `#import "UIViewController+HBD.h"` and any other HBD header import.

### Out of scope

- Full Liquid Glass adoption (translucent bar background) — preserve solid green brand.
- Large title, scroll-edge transparency transitions, search controller integration — none of these are present today; introducing them is a separate design.
- Replacing `Bugly` (sunset by Tencent in late 2024) — backlog.
- Lifting `IPHONEOS_DEPLOYMENT_TARGET` (still iOS 15.6).
- Custom in-page navigation views (`HomeNavigation`, `ChartNavigation`, `BKCNavigation`, `SearchNavigation`) — they are page-internal subviews, independent of HBD, untouched.
- Any business-logic, networking, or data-storage change.

### Validation strategy

The project has no test target. Phase 2 is verified by **manual regression** of every controller listed in Section 4. Build verification follows the Phase 1 caveat: the bar is **"main `bookkeeping` target compiles with zero errors"**, the BookMonth widget's pre-existing `<MJExtension/MJExtension.h>` failure stays out of scope.

---

## 3. Architecture

### 3.1 Global `UINavigationBarAppearance`

Configured once in `AppDelegate.systemConfig`:

```objc
- (void)systemConfig {
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = kColor_Main_Color;
    appearance.shadowColor = nil;                              // drop the bottom hairline
    appearance.titleTextAttributes = @{
        NSForegroundColorAttributeName: kColor_Text_White,
        NSFontAttributeName: [UIFont systemFontOfSize:AdjustFont(14)]
    };

    UIImage *chevron = [[UIImage imageNamed:@"nav_back_n"]
                        imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [appearance setBackIndicatorImage:chevron transitionMaskImage:chevron];

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

    [[UITextField appearance] setTintColor:kColor_Main_Color];   // pre-existing
}
```

`UINavigationBarAppearance` is iOS 13+; the deployment target (iOS 15.6) is fine.
On iOS 26 the same code keeps the opaque green background and inherits the
system's Liquid Glass treatment for bar items.

### 3.2 New `BaseNavigationController`

```objc
// .h
@interface BaseNavigationController : UINavigationController   // was HBDNavigationController
@end

// .m
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    viewController.hidesBottomBarWhenPushed = (self.viewControllers.count == 1);
    [super pushViewController:viewController animated:animated];
}
```

The `hidesBottomBarWhenPushed` line is a no-op in this app (no tab bar) but is
retained for symmetry with the Phase 1 simplification and future-proofing.

### 3.3 New `BaseViewController` hide/show contract

```objc
// .h
@interface BaseViewController : UIViewController
@property (nonatomic, assign) BOOL prefersNavigationBarHidden;
// removed: leftButton, rightButton, navTitle, setNavTitle:, etc.
@end

// .m
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:kColor_BG];
    self.navigationItem.backButtonTitle = @"返回";
    [self.navigationController.interactivePopGestureRecognizer setEnabled:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:self.prefersNavigationBarHidden
                                             animated:animated];
}
```

Phase 1's `viewWillAppear:` cleanup branch (which cleared `leftBarButtonItem` / `rightBarButtonItem` / set `hidesBackButton = YES` when `hbd_barHidden`) is removed — the iOS 26 floating glass overlays it worked around were a HBD-era artefact; native UINavigationController hides the whole bar cleanly.

### 3.4 Subclass migration shape

**Hidden-bar controllers (10)** — single line replacement:
```diff
- self.hbd_barHidden = YES;
+ self.prefersNavigationBarHidden = YES;
```

**Visible-bar controllers (14)** — typical three-line change:
```diff
- self.hbd_barHidden = NO;
- self.hbd_barTintColor = kColor_Main_Color;
- [self setNavTitle:@"修改密码"];
+ self.title = @"修改密码";
```

**Right-button conversions (in their respective controllers):**
```objc
// CAController, ACAController:
self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"完成"
                                     style:UIBarButtonItemStyleDone
                                    target:self action:@selector(rightButtonClick)];

// BillController (composite year + arrow):
UIView *yearWrapper = ({ ... year UILabel + arrow UIImageView, packed in a UIView ... });
self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithCustomView:yearWrapper];
// the existing year-refresh logic via viewWithTag:10 is preserved
```

**WebViewController** (left button overrides for WKWebView history pop):
```objc
UIImage *backImage = [[UIImage imageNamed:@"nav_back_n"]
                      imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
self.navigationItem.leftBarButtonItem =
    [[UIBarButtonItem alloc] initWithImage:backImage
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(handleBackAction)];
```

---

## 4. Per-controller migration map

### 4.1 Hidden-bar group (10)

All identical: replace `self.hbd_barHidden = YES;` with `self.prefersNavigationBarHidden = YES;`.

| Controller | Path | Notes |
|---|---|---|
| `HomeController` | `Modules/Home/Controller/` | App root |
| `MineController` | `Modules/Me/Controller/` | |
| `ChartController` | `Modules/Chart/Controller/` | |
| `BookController` | `Modules/Book/Controller/` | URL-scheme entry from BookMonth widget |
| `VerifyController` | `Modules/Verify/` | |
| `SearchViewController` | `Modules/Search/Controller/` | Has its own SEARCH_BACK event |
| `BookDetailController` | `Modules/Detail/Controller/` | Also remove dead `[self.rightButton setHidden:YES]` |
| `LoginController` | `Modules/Login/Controller/` | |
| `PasswordLoginController1` | `Modules/Login/Controller/` | |
| `PasswordLoginController2` | `Modules/Login/Controller/` | |

### 4.2 Visible-bar group (14)

All replace the `hbd_*` lines and `setNavTitle:` per §3.4. Right-button or left-button specifics:

| Controller | Path | Title | Right button | Left button |
|---|---|---|---|---|
| `BillController` | `Modules/Bill/Controller/` | 账单 | composite year + arrow → `initWithCustomView:` | (default back) |
| `PasswordController` | `Modules/Password/Controller/` | 修改密码 | — | (default back) |
| `CAController` | `Modules/Category/Controller/` | 类别设置 | "完成" → `initWithTitle:style:Done` | (default back) |
| `WebViewController` | `Modules/WebView/` | 帮助 | — | `initWithImage:` → `handleBackAction` |
| `FeedbackController` | `Modules/Feedback/` | 反馈 | — | (default back) |
| `AboutController` | `Modules/About/Controller/` | 关于 | — | (default back) |
| `DeleteAccountController` | `Modules/About/Controller/` | 删除账号 | — | (default back) |
| `TimeRemindController` | `Modules/Timing/Controller/` | 定时提醒 | — | (default back) |
| `InfoController` | `Modules/Info/Controller/` | 个人信息 | — | (default back) |
| `ACAController` | `Modules/AddCategory/Controller/` | 添加类别 | "完成" → `initWithTitle:style:Done` | (default back) |
| `RegisterController` | `Modules/Register/Controller/` | dynamic | — | (default back) |
| `AgreementWebViewController` | `Modules/Common/Controller/` | 用户协议 / 隐私政策 | — | (default back) |
| `ExportController` | `Modules/Export/` | 导出数据 | — | (default back) |
| `ShareController` | `Modules/Share/Controller/` | 分享 | — | (default back) |

### 4.3 Untouched

`HomeNavigation`, `ChartNavigation`, `BKCNavigation`, `SearchNavigation` — page-internal
subviews, not nav-bar items, stay as-is.

---

## 5. Commit boundaries

Each of the three commits must independently compile and run without runtime crashes.

### Commit 1 — `feat(nav): seed UINavigationBarAppearance + hidden-bar property`

Plant the new infrastructure with **no behavioural change**. Old (HBD) and new
(`prefersNavigationBarHidden` + `self.title`) live side by side. HBD remains
the parent of `BaseNavigationController` and continues to render bars.

| File | Change |
|---|---|
| `AppDelegate.m` | Add the §3.1 `UINavigationBarAppearance` block to `systemConfig`. HBD overrides bar rendering at runtime, so this is dormant for now. |
| `BaseViewController.h` | Add `@property (nonatomic, assign) BOOL prefersNavigationBarHidden;` |
| `BaseViewController.m` | Add `viewDidLoad` line `self.navigationItem.backButtonTitle = @"返回";`. Add `viewWillAppear:` line `[self.navigationController setNavigationBarHidden:self.prefersNavigationBarHidden animated:animated];` (parallel to HBD's hide flow). |
| 24 controllers | Hidden-bar group: also add `self.prefersNavigationBarHidden = YES;` (without removing `hbd_barHidden = YES`). Visible-bar group: also add `self.title = @"...";` (without removing `[self setNavTitle:...]`). |

### Commit 2 — `refactor(nav): switch to native UINavigationController`

The single behaviour-changing commit.

| File | Change |
|---|---|
| `BaseNavigationController.h` | Parent class `: HBDNavigationController` → `: UINavigationController`. |
| `BaseNavigationController.m` | Drop HBD/KM imports. Keep the simplified `pushViewController:animated:` (already shipped in Phase 1). |
| `BaseViewController.h/.m` | Delete `leftButton`, `rightButton`, `navTitle` properties; delete `setLeftBtn`, `setRightBtn`, `setNavTitle:`, `initUI`, `hideNavigationBarLine`, `showNavigationBarLine`. Delete the Phase 1 `viewWillAppear:` HBD-bar-hidden cleanup branch. |
| `Common.h` | Remove `#import "UIViewController+HBD.h"` (and any other HBD header imports). |
| 24 controllers | Remove all `hbd_*` lines and any `[self setNavTitle:...]`. Convert `BillController`'s composite right button to a customView wrapper plus `initWithCustomView:`. Convert `CAController` / `ACAController` right buttons to `initWithTitle:style:Done`. Delete `BookDetailController`'s dead `setHidden:YES`. Convert `WebViewController`'s left button override per §3.4. |

### Commit 3 — `chore(nav): drop HBDNavigationBar and KMNavigationBarTransition pods`

Pure dependency cleanup; no source-code change beyond the Podfile.

| File | Change |
|---|---|
| `Podfile` | Remove `pod 'HBDNavigationBar', '~> 1.9.5'`; remove `pod 'KMNavigationBarTransition', '1.1.5'`; remove the HBD KVC `@try/@catch` `post_install` patch block. |
| `Podfile.lock` / `Pods/Manifest.lock` / `Pods/Pods.xcodeproj/project.pbxproj` | Auto-regenerated by `pod install`. |
| `Pods/HBDNavigationBar/` / `Pods/KMNavigationBarTransition/` | Auto-deleted. |

After Commit 3 the dependency count drops from 16 → 14.

---

## 6. Validation matrix

### 6.1 Commit 1 — Prep

- `xcodebuild ... build` succeeds (filter to `bookkeeping` target).
- App launches, behaviour visually identical to pre-commit (HBD still rendering).
- Smoke: enter one hidden-bar page (e.g. Login) and one visible-bar page (e.g. Info). No regression.

### 6.2 Commit 2 — Cutover (the heavy step)

#### Hidden-bar group (10)

| Controller | Action | Pass criteria |
|---|---|---|
| `HomeController` | Launch | No leftover bar; in-page navigation subview renders correctly |
| `MineController` | Tab/sidebar | Same |
| `ChartController` | Enter | Same |
| `BookController` | "+" button or `kbook://month` | Own close button works |
| `VerifyController` | Login → SMS → enter code | Own close button works; no floating glass |
| `SearchViewController` | Home → search | Own back works → pop never crashes |
| `BookDetailController` | Tap a booking row | Own back works |
| `LoginController` | Launch when logged out | Own close works |
| `PasswordLoginController1/2` | Login → "密码登录" | Own close works |

#### Visible-bar group (14)

| Controller | Path | Pass criteria |
|---|---|---|
| `BillController` | Home → month picker | Green bar + "账单" + composite year+arrow right (glass-wrapped on iOS 26 but tappable) |
| `PasswordController` | Info → 修改密码 | Green + "修改密码" + system back ("返回") |
| `CAController` | Info → 类别设置 | Green + "类别设置" + system Done "完成" → fires `rightButtonClick` |
| `WebViewController` | Info → 帮助 | Green + "帮助" + custom left chevron → `handleBackAction` (WKWebView history pop, not nav pop) |
| `FeedbackController` | Info → 反馈 | Green + "反馈" + system back |
| `AboutController` | Info → 关于 | Green + "关于" + system back |
| `DeleteAccountController` | Info → 删除账号 | Green + "删除账号" + system back |
| `TimeRemindController` | Info → 定时提醒 | Green + "定时提醒" + system back |
| `InfoController` | Mine → 个人信息 | Green + "个人信息" + system back |
| `ACAController` | 类别设置 → "+" | Green + "添加类别" + system Done "完成" |
| `RegisterController` | Login → 注册 | Green + dynamic title + system back |
| `AgreementWebViewController` | 注册/登录 → 用户协议/隐私政策 | Green + agreement title + system back |
| `ExportController` | Mine → 导出数据 | Green + "导出数据" + system back |
| `ShareController` | Entry | Green + "分享" + system back |

#### Cross-cutting checks

- System edge-pop gesture: from any pushed controller, edge swipe → pop succeeds, no crash.
- iOS 26: bar items rendered as glass capsules over the green opaque bar; back gesture works; tap targets remain accurate.
- iOS 25 and earlier: bar items rendered without glass, behaviour identical.
- Pushing into any visible-bar child shows the previous controller's `backButtonTitle = @"返回"` next to the chevron.
- All Phase 1 business regressions (login, booking CRUD, charts, avatar upload, token expiry handling) still pass.

### 6.3 Commit 3 — Cleanup

- `pod install` reports `Removing HBDNavigationBar` and `Removing KMNavigationBarTransition`.
- `ls -d bookkeeping/Pods/HBDNavigationBar bookkeeping/Pods/KMNavigationBarTransition` → both gone.
- `grep -c "^[[:space:]]*pod " bookkeeping/Podfile` → `14`.
- Build clean.
- Smoke: any 3 hidden-bar pages + any 3 visible-bar pages still render and pop correctly.

### 6.4 Whole-phase rollback

```bash
git revert <commit-3>
cd bookkeeping && pod install      # restores HBD + KM pods + the KVC patch hook
git revert <commit-2>               # 24 controllers + base classes back to Commit 1 state
git revert <commit-1>               # back to Phase 1 final state on master
```

---

## 7. Risks (with mitigations)

**R1. Commit 2 size and blast radius.**
24 controllers + 4 base files change atomically. Diff is ≈ 300 lines.
*Mitigation:* Commit 1 already plants the new infrastructure. Section 6.2 lists every controller with explicit pass criteria. If something breaks and the cause is unclear, revert to Commit 1 and cherry-pick subsets.

**R2. iOS 26 system back button width.**
Glass-wrapped "返回" chevron may visually differ from expectations.
*Mitigation:* Resolved default Q1 keeps `backButtonTitle = @"返回"`. If real-device check on iOS 26 shows truncation or odd layout, swap to empty string (chevron-only).

**R3. WebView left-button hand-off.**
WebView pages depend on `handleBackAction` for WKWebView history pop, not nav stack pop.
*Mitigation:* §3.4 retains the existing `handleBackAction` logic verbatim, only swapping the wrapper from `self.leftButton` re-target to a fresh `UIBarButtonItem`.

**R4. `BillController` composite button layout.**
The original year+arrow combo manually computed its width; wrapping in `initWithCustomView:` lets the system re-position.
*Mitigation:* Keep the existing year refresh path (`viewWithTag:10`) intact. If iOS 26's glass capsule misplaces the wrapper, fall back to a plain `initWithTitle:@"YYYY 年 ▾"` — text-only.

**R5. Title font drift.**
`setNavTitle:` rendered with `[UIFont systemFontOfSize:AdjustFont(14)]`. The new appearance must use the same value; otherwise the entire app's title font size shifts.
*Mitigation:* §3.1 uses `AdjustFont(14)` — verified visually post-Commit 2.

**R6. Custom in-page navigation views drift.**
`HomeNavigation` etc. assume the system bar is hidden. Native `setNavigationBarHidden:` may differ subtly from HBD's hide path.
*Mitigation:* Section 6.2 hidden-bar verification covers each affected page. The risk is low because HBD's hidden state is essentially `UINavigationBar.hidden = YES`.

**R7. `interactivePopGestureRecognizer` regressions.**
*Mitigation:* `BaseViewController.viewDidLoad` retains the existing `setEnabled:YES` line.

---

## 8. Resolved defaults

| ID | Question | Decision |
|---|---|---|
| Q1 | `backButtonTitle` value | **`@"返回"`** (matches prior HBD behaviour) |
| Q2 | iOS 26 bar-item glass-capsule customisation | **None** — accept system default |
| Q3 | `UINavigationBar.tintColor` scope | **Global white** (consistent with green opaque background) |
| Q4 | `BookDetailController`'s dead `setHidden:YES` on rightButton | **Delete** |
| Q5 | Phase 1's `viewWillAppear:` `hbd_barHidden` cleanup branch | **Delete with HBD** (Phase 1 mitigation no longer has a target) |
| Q6 | Commented-out `jz_navigationBarTransitionStyle` in `BaseNavigationController.m` | **Delete** alongside the KMNavigationBarTransition pod |

---

## 9. After Phase 2

Once merged, follow-up candidates outside this phase:

- Replace `Bugly` (sunset Tencent SDK) with a current crash reporter — separate spec.
- Consider Large Title / scroll-edge translucency on selected pages now that the appearance pipeline exists — design-only follow-up if user wants the iOS 26 adaptive feel anywhere.
- Optional polish: drop the in-page `HomeNavigation` / `ChartNavigation` / `BKCNavigation` / `SearchNavigation` subviews in favour of UINavigationController-driven chrome on the hidden-bar pages — bigger refactor, not blocked by anything in Phase 2.
