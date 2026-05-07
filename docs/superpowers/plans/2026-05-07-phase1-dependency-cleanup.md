# Phase 1 Dependency Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove three abandoned third-party libraries (YYText, Texture, AFNetworking) from this iOS project and replace AFNetworking's wrapper with `NSURLSession`, while keeping all caller code and UI behaviour bit-identical.

**Architecture:** Three independent commits land sequentially on `master`. Commits 1 and 2 are pure deletions (the libraries are dead code). Commit 3 swaps the implementation of `AFNManager.m` against the same public `.h` API; all 21 callers and `Common.h` / `KKPrefixHeader.pch` stay untouched.

**Tech Stack:** Objective-C, CocoaPods 1.11.3, Xcode 16+ / iOS 26 SDK, deployment target iOS 15.6, `NSURLSession`, `NSURLSessionTaskDelegate`, `NSMapTable`, MJExtension (kept).

**Spec:** `docs/superpowers/specs/2026-05-07-phase1-dependency-cleanup-design.md` — all design decisions live there. This plan is the executable form.

**No automated tests.** The project has no test target. Validation is manual regression as defined in the spec §5; each task ends only after the corresponding regression has passed.

**Pre-existing build caveat.** The `BookMonth` widget extension target has a long-standing header-search-path bug (`<MJExtension/MJExtension.h>` not found at compile time). This pre-dates Phase 1 and is NOT in scope here. Whenever a build verification step says "BUILD SUCCEEDED", interpret it as: **the `bookkeeping` (main app) target compiles with zero errors**. Use the filter below to confirm:

```bash
xcodebuild ... build 2>&1 | grep -E "error:" | grep "in target 'bookkeeping' from project"
```
Expected: empty output. BookMonth-target errors are tolerated.

---

## Pre-flight

Run once at the start of execution. Working directory for everything below is the repo root: `/Users/vancexin/repository/bookkeeping-iOS`.

- [ ] **Step P.1: Confirm clean working tree**

Run:
```bash
git status --short
```
Expected: empty output. If anything is staged or modified, stop and ask the user — we don't want to bundle pre-existing edits into Phase 1 commits.

- [ ] **Step P.2: Confirm spec file is committed**

Run:
```bash
git log --oneline -1 docs/superpowers/specs/2026-05-07-phase1-dependency-cleanup-design.md
```
Expected: shows commit `148dc1e docs: phase 1 dependency cleanup design spec` (or whatever hash it landed on). If empty, the spec hasn't been committed — stop.

- [ ] **Step P.3: Snapshot the current Pod count**

Run:
```bash
grep -c "^[[:space:]]*pod " bookkeeping/Podfile
```
Expected: `18`. After all three commits, this should drop to `15`.

---

## Task 1: Remove YYText (dead-code Pod)

**Files:**
- Delete: `bookkeeping/bookkeeping/Classes/Categorys/YYLabel/YYLabel+Extension.h`
- Delete: `bookkeeping/bookkeeping/Classes/Categorys/YYLabel/YYLabel+Extension.m`
- Delete: `bookkeeping/bookkeeping/Classes/Categorys/YYLabel/` (the whole directory)
- Modify: `bookkeeping/Podfile` (remove pod line + remove `'Pods/YYText/YYText/Component/YYTextLayout.m'` from `chained_cmp_patch_targets`)
- Modify: `bookkeeping/bookkeeping.xcodeproj/project.pbxproj` (remove 8 lines referencing `YYLabel`)

**Why this is safe:** `YYLabel+Extension` is the only consumer of YYText in the entire app, and **nothing in turn imports `YYLabel+Extension.h`** (verified by grep). It is orphan code.

- [ ] **Step 1.1: Verify YYLabel is genuinely unused**

Run:
```bash
grep -rn 'import.*"YYLabel+Extension' bookkeeping/bookkeeping --include="*.h" --include="*.m"
```
Expected: only `YYLabel+Extension.m:9:#import "YYLabel+Extension.h"` (the file importing its own header). Any other hit means a real consumer exists — stop and investigate.

- [ ] **Step 1.2: Delete the YYLabel directory**

Run:
```bash
rm -rf bookkeeping/bookkeeping/Classes/Categorys/YYLabel
ls -d bookkeeping/bookkeeping/Classes/Categorys/YYLabel 2>&1
```
Expected: `ls: ...: No such file or directory`.

- [ ] **Step 1.3: Remove YYLabel references from `bookkeeping.xcodeproj/project.pbxproj`**

The `xcodeproj` Ruby gem (already installed because CocoaPods depends on it) is the only safe way to mutate this file — naive line-based deletion breaks multi-line `PBXGroup` definitions.

Run:
```bash
ruby - <<'RUBY'
require 'xcodeproj'
project = Xcodeproj::Project.open('bookkeeping/bookkeeping.xcodeproj')

# Remove file references whose path contains YYLabel+Extension.
# remove_from_project cascades: drops the file from any groups, removes
# the matching PBXBuildFile, and removes the entry from build phases.
project.files.each do |f|
  next unless f.path && f.path.include?('YYLabel+Extension')
  puts "removing file ref: #{f.path}"
  f.remove_from_project
end

# Remove the now-empty YYLabel group.
project.main_group.recursive_children.each do |g|
  next unless g.is_a?(Xcodeproj::Project::Object::PBXGroup)
  if g.path == 'YYLabel' || g.name == 'YYLabel'
    puts "removing group: YYLabel"
    g.remove_from_project
  end
end

project.save
RUBY
grep -c "YYLabel" bookkeeping/bookkeeping.xcodeproj/project.pbxproj
```
Expected: `0`.

- [ ] **Step 1.4: Remove YYText pod and its patch hook from Podfile**

Read `bookkeeping/Podfile` and apply two edits:

Edit A — remove the `pod 'YYText', '1.0.7'` line.

Replace:
```
    pod 'YYText', '1.0.7'
    pod 'YYImage', '1.0.4'
```
With:
```
    pod 'YYImage', '1.0.4'
```

Edit B — remove the YYText entry from the chained-comparison patch target list.

Replace:
```ruby
  chained_cmp_patch_targets = [
    'Pods/YYText/YYText/Component/YYTextLayout.m',
    'Pods/Texture/Source/TextExperiment/Component/ASTextLayout.mm',
  ]
```
With:
```ruby
  chained_cmp_patch_targets = [
    'Pods/Texture/Source/TextExperiment/Component/ASTextLayout.mm',
  ]
```

After both edits run:
```bash
grep -n "YYText" bookkeeping/Podfile
```
Expected: empty output.

- [ ] **Step 1.5: Re-resolve Pods**

Run:
```bash
cd bookkeeping && pod install 2>&1 | tail -10
```
Expected: contains `Pod installation complete!`. The line `[patch] chained-comparison fixed in Pods/YYText/...` should NOT appear (the target list no longer includes YYText). The `Pods/YYText/` directory should be gone:
```bash
ls -d bookkeeping/Pods/YYText 2>&1
```
Expected: `ls: ...: No such file or directory`.

- [ ] **Step 1.6: Build to confirm zero compile errors**

Run:
```bash
xcodebuild -workspace bookkeeping/bookkeeping.xcworkspace \
           -scheme bookkeeping \
           -configuration Debug \
           -sdk iphonesimulator \
           -destination 'generic/platform=iOS Simulator' \
           build 2>&1 | tail -20
```
Expected: ends with `** BUILD SUCCEEDED **`. If it fails with a "no such file" or "module not found" error mentioning YYText / YYLabel, stop — something still references it.

- [ ] **Step 1.7: Smoke test — App launches**

Run the app in the simulator (Cmd+R from Xcode, or `xcrun simctl ...`). Confirm it launches to either the home screen (if logged in) or the verification-code login screen (if logged out). No additional functional verification is required for this task because YYLabel was orphan code.

- [ ] **Step 1.8: Commit**

Run:
```bash
git add bookkeeping/Podfile \
        bookkeeping/Podfile.lock \
        bookkeeping/Pods/Manifest.lock \
        bookkeeping/Pods/Pods.xcodeproj/project.pbxproj \
        bookkeeping/bookkeeping.xcodeproj/project.pbxproj
git rm -r --cached bookkeeping/Pods/YYText 2>/dev/null || true   # noop if not tracked
git status --short
```
Verify the staged set looks like:
- `M` Podfile, Podfile.lock, Manifest.lock, Pods.xcodeproj, bookkeeping.xcodeproj
- (deletions of YYLabel files appear as `D` automatically because the rm above)
- (deletions inside `Pods/YYText/` if they were tracked)

Then commit:
```bash
git add -A bookkeeping/Pods/YYText bookkeeping/bookkeeping/Classes/Categorys/YYLabel 2>/dev/null
git commit -m "chore: remove unused YYText dependency"
```

Expected: commit succeeds. Run `git status` — working tree clean.

---

## Task 2: Remove Texture / AsyncDisplayKit (dead-code Pod)

**Files:**
- Delete: `bookkeeping/bookkeeping/Classes/Base/controller/ASBaseViewController.h`
- Delete: `bookkeeping/bookkeeping/Classes/Base/controller/ASBaseViewController.m`
- Delete: `bookkeeping/bookkeeping/Classes/Base/view/ASBaseTableCell.h`
- Delete: `bookkeeping/bookkeeping/Classes/Base/view/ASBaseTableCell.m`
- Modify: `bookkeeping/bookkeeping/Classes/Base/controller/BaseNavigationController.m` (remove `#import <AsyncDisplayKit/AsyncDisplayKit.h>` on line 7)
- Modify: `bookkeeping/bookkeeping/Common.h` (remove `#import "ASBaseViewController.h"` on line 42)
- Modify: `bookkeeping/Podfile` (remove pod line + remove Texture from `chained_cmp_patch_targets`)
- Modify: `bookkeeping/bookkeeping.xcodeproj/project.pbxproj` (remove 12 lines referencing `ASBaseViewController` / `ASBaseTableCell`)

**Why this is safe:** `ASBaseViewController` and `ASBaseTableCell` have **zero subclasses** (verified by grep). The only references are the files themselves and one umbrella header import. The library is dead weight, ~5–8 MB of binary size.

- [ ] **Step 2.1: Verify ASBase is genuinely unused**

Run subclass scan:
```bash
grep -rn ': ASBaseViewController\b\|: ASBaseTableCell\b' bookkeeping/bookkeeping --include="*.h" --include="*.m"
```
Expected: empty output. Any hit = a real subclass — stop.

Run import scan:
```bash
grep -rn 'import.*"ASBase' bookkeeping/bookkeeping --include="*.h" --include="*.m"
```
Expected: only the four ASBase files themselves importing each other plus `Common.h:42`. If any *Modules/* file shows up, stop.

Run **class-name usage scan** (catches call sites like `[ASBaseViewController class]`, `(ASBaseViewController *)cast`, etc. — separate from imports):
```bash
grep -rn "ASBaseViewController\|ASBaseTableCell" bookkeeping/bookkeeping --include="*.h" --include="*.m" | grep -v 'import.*"ASBase\|/ASBase'
```
Expected output (any hit must be inspected before proceeding):
```
bookkeeping/bookkeeping/Classes/Base/controller/BaseNavigationController.m:24:    if (![viewController isKindOfClass:[ASBaseViewController class]]) {
bookkeeping/bookkeeping/Classes/Base/controller/BaseNavigationController.m:36:            ASBaseViewController *vc = (ASBaseViewController *)viewController;
bookkeeping/bookkeeping/Classes/Base/controller/BaseNavigationController.m:40:            ASBaseViewController *vc = (ASBaseViewController *)viewController;
```

These three lines live in a `pushViewController:animated:` else-branch that special-cases `ASBaseViewController` subclasses. Since there are zero subclasses, that branch is dead. Step 2.3 (below) replaces the entire method body with the simplified non-AS path.

- [ ] **Step 2.2: Delete the four ASBase files**

Run:
```bash
rm bookkeeping/bookkeeping/Classes/Base/controller/ASBaseViewController.h
rm bookkeeping/bookkeeping/Classes/Base/controller/ASBaseViewController.m
rm bookkeeping/bookkeeping/Classes/Base/view/ASBaseTableCell.h
rm bookkeeping/bookkeeping/Classes/Base/view/ASBaseTableCell.m
ls bookkeeping/bookkeeping/Classes/Base/controller/AS* bookkeeping/bookkeeping/Classes/Base/view/AS* 2>&1
```
Expected: `ls: ...: No such file or directory`.

- [ ] **Step 2.3: Strip AsyncDisplayKit import + collapse the dead AS branch in `BaseNavigationController.m`**

Edit A — remove the import line:

Replace:
```objc
#import "BaseNavigationController.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
```
With:
```objc
#import "BaseNavigationController.h"
```

Edit B — collapse the dead `ASBaseViewController` branch in `pushViewController:animated:` and clean out the surrounding commented-out scaffolding. Replace the entire method:
```objc
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (![viewController isKindOfClass:[ASBaseViewController class]]) {
        if (self.viewControllers.count == 1) {
            BaseViewController *vc = (BaseViewController *)viewController;
            vc.leftButton.hidden = true;
            vc.hidesBottomBarWhenPushed = true;
        } else {
            BaseViewController *vc = (BaseViewController *)viewController;
            vc.leftButton.hidden = true;
            vc.hidesBottomBarWhenPushed = false;
        }
    } else {
        if (self.viewControllers.count == 1) {
            ASBaseViewController *vc = (ASBaseViewController *)viewController;
//            vc.leftButton.hidden = true;
            vc.hidesBottomBarWhenPushed = true;
        } else {
            ASBaseViewController *vc = (ASBaseViewController *)viewController;
//            vc.leftButton.hidden = true;
            vc.hidesBottomBarWhenPushed = false;
        }
    }
    
    
    
//    BaseTabBarController *tab = (BaseTabBarController *)[UIApplication sharedApplication].keyWindow.rootViewController;
//    if ([viewController isKindOfClass:[HomeController class]] ||
//        [viewController isKindOfClass:[ChartController class]] ||
//        [viewController isKindOfClass:[BKCController class]] ||
//        [viewController isKindOfClass:[FindController class]] ||
//        [viewController isKindOfClass:[MineController class]]) {
//        BaseViewController *vc = (BaseViewController *)viewController;
//        vc.leftButton.hidden = YES;
////        [tab hideTabbar:NO];
//    }
//    else {
//        BaseViewController *vc = (BaseViewController *)viewController;
//        vc.leftButton.hidden = NO;
//        vc.hidesBottomBarWhenPushed = YES;
////        [tab hideTabbar:YES];
//    }
    
    
    
    [super pushViewController:viewController animated:animated];
}
```
With:
```objc
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    BaseViewController *vc = (BaseViewController *)viewController;
    vc.leftButton.hidden = true;
    vc.hidesBottomBarWhenPushed = (self.viewControllers.count == 1);
    [super pushViewController:viewController animated:animated];
}
```

Behavior preservation: this collapses two identical-up-to-cast branches into one, removing only the dead AS branch (which was unreachable because no controller subclassed `ASBaseViewController`). The non-AS path's logic — set `leftButton.hidden = true` + `hidesBottomBarWhenPushed = (count == 1)` — is preserved exactly.

Verify:
```bash
grep -n "AsyncDisplayKit\|ASBase" bookkeeping/bookkeeping/Classes/Base/controller/BaseNavigationController.m
```
Expected: empty output.

- [ ] **Step 2.4: Remove the ASBaseViewController import from `Common.h`**

Use the Edit tool to remove line 42 of `bookkeeping/bookkeeping/Common.h`:

Replace:
```objc
#import "BaseTabBarController.h"
#import "BaseNavigationController.h"
#import "BaseTableCell.h"
#import "ASBaseViewController.h"

//================================= Category =================================//
```
With:
```objc
#import "BaseTabBarController.h"
#import "BaseNavigationController.h"
#import "BaseTableCell.h"

//================================= Category =================================//
```

Verify:
```bash
grep -n "ASBase" bookkeeping/bookkeeping/Common.h
```
Expected: empty output.

- [ ] **Step 2.5: Strip ASBase entries from `bookkeeping.xcodeproj/project.pbxproj`**

Same `xcodeproj` Ruby-gem approach as Step 1.3. The four ASBase files live in existing parent groups (`Base/controller`, `Base/view`); no dedicated group needs deleting, but using the gem still avoids any risk of breaking multi-line constructs.

Run:
```bash
ruby - <<'RUBY'
require 'xcodeproj'
project = Xcodeproj::Project.open('bookkeeping/bookkeeping.xcodeproj')
targets = ['ASBaseViewController.h', 'ASBaseViewController.m',
           'ASBaseTableCell.h', 'ASBaseTableCell.m']
project.files.each do |f|
  next unless f.path && targets.include?(File.basename(f.path))
  puts "removing file ref: #{f.path}"
  f.remove_from_project
end
project.save
RUBY
grep -cE "ASBaseViewController|ASBaseTableCell" bookkeeping/bookkeeping.xcodeproj/project.pbxproj
```
Expected: `0`.

- [ ] **Step 2.6: Remove Texture pod and its patch hook from Podfile**

Edit A — remove `pod 'Texture', '3.1.0'`:

Replace:
```ruby
    pod 'BRPickerView', '2.9.1'
    pod 'Texture', '3.1.0'
    pod 'YYImage', '1.0.4'
```
With:
```ruby
    pod 'BRPickerView', '2.9.1'
    pod 'YYImage', '1.0.4'
```

Edit B — empty the `chained_cmp_patch_targets` array (Texture was the last entry; YYText was already removed in Task 1).

Replace:
```ruby
  # 修复 YYText 1.0.7 / Texture 内嵌 YYText 实验组件的链式比较 bug
  # （两个仓库都已归档未修，新版 Clang 把这个 warning 升级为 error）
  # 原写法 `A < B < (right ? prev : next)` 会被解析成 `(A<B) < (...)`，position 永远是 0/1
  chained_cmp_patch_targets = [
    'Pods/Texture/Source/TextExperiment/Component/ASTextLayout.mm',
  ]
  chained_cmp_patch_targets.each do |relative|
    path = File.join(installer.config.installation_root, relative)
    next unless File.exist?(path)
    original = File.read(path)
    patched = original.gsub(
      /position = fabs\(left - point\.([xy])\) < fabs\(right - point\.\1\) < \(right \? prev : next\);/,
      'position = fabs(left - point.\1) < fabs(right - point.\1) ? prev : next;'
    )
    next if patched == original
    File.chmod(0644, path)
    File.write(path, patched)
    Pod::UI.puts "[patch] chained-comparison fixed in #{relative}".yellow
  end

```
With:
```ruby
```
(i.e. delete the entire block including the trailing blank line)

Verify:
```bash
grep -n "Texture\|chained_cmp_patch_targets" bookkeeping/Podfile
```
Expected: empty output.

- [ ] **Step 2.7: Re-resolve Pods**

Run:
```bash
cd bookkeeping && pod install 2>&1 | tail -10
```
Expected: contains `Pod installation complete!`. No `[patch] chained-comparison ...` line should appear (the target list is gone). The `Pods/Texture/` directory should be gone:
```bash
ls -d bookkeeping/Pods/Texture 2>&1
```
Expected: `ls: ...: No such file or directory`.

- [ ] **Step 2.8: Build to confirm zero compile errors**

Run:
```bash
xcodebuild -workspace bookkeeping/bookkeeping.xcworkspace \
           -scheme bookkeeping \
           -configuration Debug \
           -sdk iphonesimulator \
           -destination 'generic/platform=iOS Simulator' \
           build 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`. If you see "module 'AsyncDisplayKit' not found" or "unknown receiver 'ASBaseViewController'", stop — there's a hidden reference.

- [ ] **Step 2.9: Functional smoke test**

Run the app in the simulator. Verify:
1. Home screen renders the booking list with normal scrolling (`HomeList` extends `BaseTableView`, not `ASCellNode` — confirms removal didn't affect production rendering).
2. Push at least one secondary screen (e.g., enter the chart tab, then tap into a booking detail) and pop back. Pop transitions are smooth.

If either fails, the `BaseNavigationController` change has side-effects we missed. Stop and inspect.

- [ ] **Step 2.10: Commit**

Run:
```bash
git add -A bookkeeping/Podfile \
           bookkeeping/Podfile.lock \
           bookkeeping/Pods/Manifest.lock \
           bookkeeping/Pods/Pods.xcodeproj/project.pbxproj \
           bookkeeping/Pods/Texture \
           bookkeeping/bookkeeping.xcodeproj/project.pbxproj \
           bookkeeping/bookkeeping/Common.h \
           bookkeeping/bookkeeping/Classes/Base/controller/BaseNavigationController.m \
           bookkeeping/bookkeeping/Classes/Base/controller/ASBaseViewController.h \
           bookkeeping/bookkeeping/Classes/Base/controller/ASBaseViewController.m \
           bookkeeping/bookkeeping/Classes/Base/view/ASBaseTableCell.h \
           bookkeeping/bookkeeping/Classes/Base/view/ASBaseTableCell.m
git status --short
```
Verify the staged set:
- `M` Podfile, Podfile.lock, Manifest.lock, Pods.xcodeproj, bookkeeping.xcodeproj, Common.h, BaseNavigationController.m
- `D` for the four ASBase* files
- Many `D` lines for tracked Pods/Texture/*

Then:
```bash
git commit -m "chore: remove unused Texture (AsyncDisplayKit) dependency"
```

Expected: commit succeeds, `git status` clean.

---

## Task 3: Rewrite AFNManager on NSURLSession

**Files:**
- Modify: `bookkeeping/bookkeeping/Classes/Network/AFNManager.m` (full rewrite)
- Modify: `bookkeeping/Podfile` (remove `pod 'AFNetworking', '4.0.1'` and the `afn_private_header_targets` block)

**API contract — must NOT change:**
- `AFNManager.h` byte-identical
- `+ POST:params:complete:` signature unchanged
- `+ POST:params:progress:complete:` signature unchanged
- `+ POST:params:images:progress:complete:` signature unchanged
- All `complete:` and `progress:` blocks invoked on the main queue
- Authorization header auto-refresh from response → `UserInfo`
- `app_id: 638c2977f1b24ba0` on every request
- On `result.code == TOKEN_EXPIRED`: post `MINE_TOKEN_EXPIRED`, **do not** invoke `complete:`
- Failure path: `APPResult` with `status = HttpStatusFail`, `cache = CacheStatusFail`, `msg = @"请求失败"`
- Multipart: PNG → JPEG fallback, drop image if both encodings fail

- [ ] **Step 3.1: Read `AFNManager.h` to confirm the contract**

Run:
```bash
sed -n '1,40p' bookkeeping/bookkeeping/Classes/Network/AFNManager.h
```
Expected output should show three `+ POST:` declarations and the `AFNManagerCompleteBlock` / `AFNManagerProgressBlock` typedefs. **Do not modify this file.**

- [ ] **Step 3.2: Replace `AFNManager.m` with the NSURLSession implementation**

Open `bookkeeping/bookkeeping/Classes/Network/AFNManager.m` and replace the entire file contents with the block below. (Use `cp` to keep a backup if desired: `cp bookkeeping/bookkeeping/Classes/Network/AFNManager.m /tmp/AFNManager.m.bak`.)

```objc
//
//  AFNManager.m
//  bookkeeping
//
//  Rewritten on NSURLSession in 2026-05 to drop the AFNetworking 4.0.1
//  dependency. Public API is identical to the previous implementation —
//  see AFNManager.h. The behavioural contract (Authorization refresh,
//  app_id header, TOKEN_EXPIRED notification, main-queue callbacks,
//  PNG→JPEG fallback) is documented in
//  docs/superpowers/specs/2026-05-07-phase1-dependency-cleanup-design.md
//

#import "AFNManager.h"

static NSString * const kAppIDHeader = @"app_id";
static NSString * const kAppIDValue  = @"638c2977f1b24ba0";

#pragma mark - Private declaration

@interface AFNManager () <NSURLSessionTaskDelegate>

+ (instancetype)shared;

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMapTable<NSURLSessionTask *, AFNManagerProgressBlock> *progressBlocks;
@property (nonatomic, strong) NSLock *progressLock;

@end

#pragma mark - Implementation

@implementation AFNManager

#pragma mark - Singleton

+ (instancetype)shared {
    static AFNManager *_shared;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _shared = [[AFNManager alloc] init];
    });
    return _shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
        cfg.timeoutIntervalForRequest  = 30.0;
        cfg.timeoutIntervalForResource = 60.0;
        cfg.URLCache = nil;
        _session = [NSURLSession sessionWithConfiguration:cfg
                                                 delegate:self
                                            delegateQueue:nil];
        _progressBlocks = [NSMapTable strongToStrongObjectsMapTable];
        _progressLock = [[NSLock alloc] init];
    }
    return self;
}

#pragma mark - Public class methods

+ (void)POST:(NSString *)url
      params:(NSDictionary *)params
    complete:(AFNManagerCompleteBlock)complete {
    [self POST:url params:params progress:nil complete:complete];
}

+ (void)POST:(NSString *)url
      params:(NSDictionary *)params
    progress:(AFNManagerProgressBlock)progress
    complete:(AFNManagerCompleteBlock)complete {

    AFNManager *m = [self shared];
    NSMutableURLRequest *req = [m buildJSONRequestForURL:url params:params];
    if (req == nil) {
        [m deliverFailureToComplete:complete];
        return;
    }

    __block NSURLSessionDataTask *task = nil;
    task = [m.session dataTaskWithRequest:req
                        completionHandler:^(NSData *data, NSURLResponse *resp, NSError *error) {
        [m handleResponse:resp data:data error:error complete:complete forTask:task];
    }];

    if (progress) {
        [m setProgressBlock:progress forTask:task];
    }
    [task resume];
}

+ (void)POST:(NSString *)url
      params:(NSDictionary *)params
      images:(NSArray<UIImage *> *)images
    progress:(AFNManagerProgressBlock)progress
    complete:(AFNManagerCompleteBlock)complete {

    AFNManager *m = [self shared];

    NSURL *u = [NSURL URLWithString:url];
    if (u == nil) {
        [m deliverFailureToComplete:complete];
        return;
    }

    NSString *boundary = [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
    NSData *body = [m buildMultipartBodyWithParams:params images:images boundary:boundary];

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:u];
    req.HTTPMethod = @"POST";
    [req setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary]
forHTTPHeaderField:@"Content-Type"];
    NSString *auth = [UserInfo getAuthorizationToken];
    if (auth) {
        [req setValue:auth forHTTPHeaderField:@"Authorization"];
    }
    [req setValue:kAppIDValue forHTTPHeaderField:kAppIDHeader];

    __block NSURLSessionUploadTask *task = nil;
    task = [m.session uploadTaskWithRequest:req
                                   fromData:body
                          completionHandler:^(NSData *data, NSURLResponse *resp, NSError *error) {
        [m handleResponse:resp data:data error:error complete:complete forTask:task];
    }];

    if (progress) {
        [m setProgressBlock:progress forTask:task];
    }
    [task resume];
}

#pragma mark - Request building

- (NSMutableURLRequest *)buildJSONRequestForURL:(NSString *)url params:(NSDictionary *)params {
    NSURL *u = [NSURL URLWithString:url];
    if (u == nil) {
        return nil;
    }

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:u];
    req.HTTPMethod = @"POST";
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [req setValue:kAppIDValue forHTTPHeaderField:kAppIDHeader];

    NSString *auth = [UserInfo getAuthorizationToken];
    if (auth) {
        [req setValue:auth forHTTPHeaderField:@"Authorization"];
    }

    if (params) {
        NSError *err = nil;
        NSData *bodyData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&err];
        if (err || bodyData == nil) {
            return nil;
        }
        req.HTTPBody = bodyData;
    }
    return req;
}

- (NSData *)buildMultipartBodyWithParams:(NSDictionary *)params
                                  images:(NSArray<UIImage *> *)images
                                boundary:(NSString *)boundary {
    NSMutableData *body = [NSMutableData data];
    NSData *crlf = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];

    [params enumerateKeysAndObjectsUsingBlock:^(id k, id v, BOOL *stop) {
        NSString *key = [NSString stringWithFormat:@"%@", k];
        NSString *val = [NSString stringWithFormat:@"%@", v];
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[val dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:crlf];
    }];

    for (NSInteger i = 0; i < (NSInteger)images.count; i++) {
        UIImage *image = images[i];
        NSData *data = UIImagePNGRepresentation(image);
        if (data == nil) {
            data = UIImageJPEGRepresentation(image, 1.0);
        }
        if (data == nil) {
            continue; // match prior AFN behaviour: skip un-encodable image
        }
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"image%ld\"\r\n", (long)i] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: image/png\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:data];
        [body appendData:crlf];
    }

    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    return body;
}

#pragma mark - Progress map

- (void)setProgressBlock:(AFNManagerProgressBlock)block forTask:(NSURLSessionTask *)task {
    AFNManagerProgressBlock copied = [block copy];
    [_progressLock lock];
    [_progressBlocks setObject:copied forKey:task];
    [_progressLock unlock];
}

- (void)removeProgressBlockForTask:(NSURLSessionTask *)task {
    if (task == nil) return;
    [_progressLock lock];
    [_progressBlocks removeObjectForKey:task];
    [_progressLock unlock];
}

#pragma mark - Response handling

- (void)deliverFailureToComplete:(AFNManagerCompleteBlock)complete {
    if (complete == nil) return;
    APPResult *r = [[APPResult alloc] init];
    r.data = nil;
    r.status = HttpStatusFail;
    r.cache = CacheStatusFail;
    r.msg = @"请求失败";
    dispatch_async(dispatch_get_main_queue(), ^{
        complete(r);
    });
}

- (void)handleResponse:(NSURLResponse *)response
                  data:(NSData *)data
                 error:(NSError *)error
              complete:(AFNManagerCompleteBlock)complete
               forTask:(NSURLSessionTask *)task {

    // 1) Refresh Authorization header from response (if present)
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSDictionary *headers = ((NSHTTPURLResponse *)response).allHeaderFields;
        if ([headers isKindOfClass:[NSDictionary class]] &&
            [headers.allKeys containsObject:@"Authorization"]) {
            id newAuth = headers[@"Authorization"];
            if ([newAuth isKindOfClass:[NSString class]] && [(NSString *)newAuth length] > 0) {
                [UserInfo saveAuthorizationToken:(NSString *)newAuth];
                [UserInfo saveAuthorizationTimestamp];
            }
        }
    }

    // 2) Failure path
    if (error) {
        [self removeProgressBlockForTask:task];
        [self deliverFailureToComplete:complete];
        return;
    }

    // 3) JSON decode → APPResult (preserves MJExtension call)
    id obj = nil;
    if (data.length > 0) {
        obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    }
    APPResult *result = obj ? [APPResult mj_objectWithKeyValues:obj] : nil;
    if (result == nil) {
        [self removeProgressBlockForTask:task];
        [self deliverFailureToComplete:complete];
        return;
    }

    // 4) Token expired path — match prior contract: post notification, do NOT call complete:
    if (result.code == TOKEN_EXPIRED) {
        [self removeProgressBlockForTask:task];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:MINE_TOKEN_EXPIRED object:nil];
        });
        return;
    }

    // 5) Success path
    result.status = HttpStatusSuccess;
    result.cache  = CacheStatusSuccess;
    [self removeProgressBlockForTask:task];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (complete) {
            complete(result);
        }
    });
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {

    [_progressLock lock];
    AFNManagerProgressBlock block = [_progressBlocks objectForKey:task];
    [_progressLock unlock];

    if (block == nil) return;

    CGFloat pct = (totalBytesExpectedToSend > 0)
        ? (CGFloat)totalBytesSent / (CGFloat)totalBytesExpectedToSend
        : 0;

    dispatch_async(dispatch_get_main_queue(), ^{
        block((CGFloat)totalBytesSent, (CGFloat)totalBytesExpectedToSend, pct);
    });
}

@end
```

Verify:
```bash
wc -l bookkeeping/bookkeeping/Classes/Network/AFNManager.m
grep -c "AFNetworking\|AFHTTPSessionManager" bookkeeping/bookkeeping/Classes/Network/AFNManager.m
```
Expected: about 230 lines, and `0` AFNetworking references.

- [ ] **Step 3.3: Remove AFNetworking from Podfile**

Edit A — remove `pod 'AFNetworking', '4.0.1'`:

Replace:
```ruby
    pod 'MJExtension', '3.0.15'
    pod 'AFNetworking', '4.0.1'
    pod 'JGProgressHUD', '2.0.3'
```
With:
```ruby
    pod 'MJExtension', '3.0.15'
    pod 'JGProgressHUD', '2.0.3'
```

Edit B — remove the entire AFNetworking patch block. Delete:
```ruby
  # 修复 AFNetworking 4.0.1 在 Xcode 16 / 新 SDK 下的 module 报错
  # `<netinet6/in6.h>` 在新 SDK 已被设为模块私有，删掉即可（IPv6 类型由 <netinet/in.h> 传递引入）
  afn_private_header_targets = [
    'Pods/AFNetworking/AFNetworking/AFNetworkReachabilityManager.m',
    'Pods/AFNetworking/AFNetworking/AFHTTPSessionManager.m',
  ]
  afn_private_header_targets.each do |relative|
    path = File.join(installer.config.installation_root, relative)
    next unless File.exist?(path)
    original = File.read(path)
    patched = original.gsub(/^#import <netinet6\/in6\.h>\n/, '')
    next if patched == original
    File.chmod(0644, path)
    File.write(path, patched)
    Pod::UI.puts "[patch] removed private <netinet6/in6.h> import from #{relative}".yellow
  end

```
(including the blank line that follows it)

Verify:
```bash
grep -n "AFNetworking\|afn_private_header_targets" bookkeeping/Podfile
```
Expected: empty output.

- [ ] **Step 3.4: Re-resolve Pods**

Run:
```bash
cd bookkeeping && pod install 2>&1 | tail -10
```
Expected: contains `Pod installation complete!`. The `[!] AFNetworking has been deprecated` warning should be gone (it was the only thing emitting that). The `Pods/AFNetworking/` directory should be gone:
```bash
ls -d bookkeeping/Pods/AFNetworking 2>&1
```
Expected: `ls: ...: No such file or directory`.

- [ ] **Step 3.5: Build**

Run:
```bash
xcodebuild -workspace bookkeeping/bookkeeping.xcworkspace \
           -scheme bookkeeping \
           -configuration Debug \
           -sdk iphonesimulator \
           -destination 'generic/platform=iOS Simulator' \
           build 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`. Compile errors mentioning `AFNetworking` / `AFHTTPSessionManager` would point to a stray import — there should be none.

- [ ] **Step 3.6: Endpoint regression matrix (simulator)**

Run the app in the simulator and walk through these scenarios in order. **Each must succeed before moving to the next.** If any fails, capture the failure (request URL, response body, console log) and stop — do not commit.

| # | Path | Endpoint hit | Pass criteria |
|---|---|---|---|
| 1 | App launch (logged-in user) | `allBookListRequest` | Home shows current month's records |
| 2 | Logout, then SMS code login | `userSmsCodeRequest` → `userLoginRequest` | Reaches home screen |
| 3 | Logout, then password login | `userLoginRequest` | Reaches home screen |
| 4 | Settings → Logout | `userLogoutRequest` | Returns to login screen |
| 5 | Profile → Change password | `ChangePassRequest` | Success toast |
| 6 | Add new booking | `bookDetailSaveRequest` | New row appears immediately on home list |
| 7 | Edit a booking | `bookDetailUpdateRequest` | Edited fields persist after going back to home |
| 8 | Delete a booking | `bookDetailDeleteRequest` | Row disappears |
| 9 | Charts tab | `getBookGroupRequest` | Chart data renders |
| 10 | Add a new category | `AddInsertCategoryListRequest` | New category appears in the list |
| 11 | Delete a category | `RemoveInsertCategoryListRequest` | Category removed |
| 12 | Profile (info) screen | `userInfoRequest` | Profile data displays |
| 13 | Edit nickname / gender / etc. | `updateUserInfoRequest` | Change persists across navigation |
| 15 | Settings → Delete account | `DeleteAccountRequest` | Logged out |

(Tests #14 and #16 are deferred to Step 3.7 — they require a real device.)

Cross-cutting checks during the run:
- Set a breakpoint inside any `complete:` block (e.g., in `LoginController.getSmsCodeRequest`'s response). Verify `[NSThread isMainThread]` evaluates `YES` when hit.
- If you have Charles/Proxyman intercepting the simulator, verify every request carries `app_id: 638c2977f1b24ba0`.
- After login, observe a subsequent request's response in the proxy and verify the `Authorization` response header (if present) matches the next outgoing request's `Authorization` header.
- Toggle airplane mode mid-app, fire any request: HUD should hide and the screen should display "请求失败" or equivalent.

- [ ] **Step 3.7: Real-device verification (multipart + token expiry)**

These two scenarios MUST run on a physical device — multipart/upload behaviour and certificate handling can differ from the simulator.

| # | Path | Endpoint | Pass criteria |
|---|---|---|---|
| 14 | Profile → tap avatar → pick photo → upload | `uploadAvatarRequest` | Avatar updates on screen; progress callback fires (verify by setting a breakpoint in the upload's `progress:` block); main-thread; no crash |
| 16 | Token expiry | (force expiry server-side, OR ask backend to set the next request's response `code` to `TOKEN_EXPIRED`) | `MINE_TOKEN_EXPIRED` notification fires; user is bounced to the login screen; no `complete:` block invoked |

If #14 fails (avatar doesn't change, or progress callback doesn't fire), inspect:
- The multipart body (log `body.length` and the boundary string in `buildMultipartBodyWithParams:` temporarily).
- Whether `UIImagePNGRepresentation` returns nil for the picked image (test by adding a `NSLog`).

If #16 fails (no notification, or `complete:` is called), inspect `handleResponse:` step 4 — confirm the `if (result.code == TOKEN_EXPIRED)` branch is taken before step 5.

- [ ] **Step 3.8: Commit**

Run:
```bash
git add bookkeeping/bookkeeping/Classes/Network/AFNManager.m \
        bookkeeping/Podfile \
        bookkeeping/Podfile.lock \
        bookkeeping/Pods/Manifest.lock \
        bookkeeping/Pods/Pods.xcodeproj/project.pbxproj
git add -A bookkeeping/Pods/AFNetworking 2>/dev/null
git status --short
```
Verify the staged set:
- `M` AFNManager.m, Podfile, Podfile.lock, Manifest.lock, Pods.xcodeproj
- `D` for everything under `Pods/AFNetworking/`

Then:
```bash
git commit -m "$(cat <<'EOF'
refactor: rewrite AFNManager on NSURLSession, drop AFNetworking

Public API of AFNManager is unchanged (same three +POST: signatures,
same threading, same Authorization/app_id/TOKEN_EXPIRED contract,
same multipart PNG→JPEG fallback). All 21 callers untouched.

Removes the AFNetworking 4.0.1 Pod and its post_install patch hook
that worked around the <netinet6/in6.h> private-header issue.
EOF
)"
```

Expected: commit succeeds, `git status` clean.

---

## Final verification

- [ ] **Step F.1: Pod count drops to 15**

Run:
```bash
grep -c "^[[:space:]]*pod " bookkeeping/Podfile
```
Expected: `15`.

- [ ] **Step F.2: All three Pod directories are gone**

Run:
```bash
ls -d bookkeeping/Pods/YYText bookkeeping/Pods/Texture bookkeeping/Pods/AFNetworking 2>&1
```
Expected: three "No such file or directory" errors.

- [ ] **Step F.3: Podfile post_install is leaner**

Run:
```bash
grep -c "patch" bookkeeping/Podfile
```
Expected: only the HBDNavigationBar patch hook should remain. Compare to the count before Phase 1 (which had YYText/Texture/AFNetworking patch references). Approximate expected: drops from ~7 patch lines to ~3.

- [ ] **Step F.4: Final commit log review**

Run:
```bash
git log --oneline -5
```
Expected: three new commits at the top:
```
<hash> refactor: rewrite AFNManager on NSURLSession, drop AFNetworking
<hash> chore: remove unused Texture (AsyncDisplayKit) dependency
<hash> chore: remove unused YYText dependency
<hash> docs: phase 1 dependency cleanup design spec
...
```

If everything above is green, Phase 1 is complete. Phase 2 (HBDNavigationBar removal + Liquid Glass adaptation) gets its own brainstorming session — do not start that work in this session.

---

## Rollback procedures

If a single commit needs to be reverted:

```bash
git revert <commit-hash>
cd bookkeeping && pod install
```

If the entire phase needs to be backed out:

```bash
git revert <commit-3-hash> <commit-2-hash> <commit-1-hash>
cd bookkeeping && pod install
```

The Podfile `post_install` hooks are designed to be idempotent and guarded by `File.exist?` checks, so re-applying patches after a revert (which restores the patch code itself) is safe and automatic.
