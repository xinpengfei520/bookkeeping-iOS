# Phase 1 — Dependency Cleanup & Networking Migration

**Date:** 2026-05-07
**Status:** Approved (sections 1–5)
**Owner:** Xin Vance
**Companion phase:** Phase 2 — Native Navigation & Liquid Glass (separate spec, not yet started)

---

## 1. Background

The bookkeeping iOS project currently depends on four third-party libraries that have been abandoned upstream and are now causing recurring maintenance pain on Xcode 16 / iOS 26:

- **AFNetworking 4.0.1** — last release Apr 2020, deprecated in favor of Alamofire; needed two source patches to compile against the latest SDK (`<netinet6/in6.h>` private-header issue).
- **Texture (AsyncDisplayKit) 3.1.0** — last release in 2019; carries the same chained-comparison bug as YYText (forked from it), patched at the source level.
- **YYText 1.0.7** — last tag 2016, archived; chained-comparison bug patched at the source level.
- **HBDNavigationBar 1.9.5** — actively crashes on iOS 26 because of `valueForKeyPath:@"visualProvider.contentView"` against the new Swift visual provider; currently mitigated by an `@try/@catch` patch.

The user requested that these libraries be replaced with system APIs where possible, and that the project be adapted to iOS 26's Liquid Glass design language.

A scope scan showed the four migrations are highly uneven in size and risk:

| Library | Direct API surface in app code | Real work |
|---|---|---|
| AFNetworking | `AFNManager.m` only (one file). 21 other files use the wrapper indirectly. | Rewrite one file. |
| Texture | `ASBaseViewController` and `ASBaseTableCell` have **zero subclasses**; `BaseNavigationController.m` only imports the umbrella header. | Delete 4 files. Effectively dead code. |
| YYText | Only `YYLabel+Extension.{h,m}` references it; **no controller in the app instantiates a `YYLabel`**. | Delete 2 files. Effectively dead code. |
| HBDNavigationBar | 26 files use `hbd_*` properties; `BaseNavigationController` inherits from `HBDNavigationController`; the entire app navigation layer depends on its transparent bar / animated transition behaviour. | Multi-controller refactor; design-heavy; intrinsically tied to iOS 26 Liquid Glass adoption. |

Because of the risk asymmetry, the work has been split into two independent specs. **This spec covers Phase 1 only.** HBDNavigationBar removal and Liquid Glass adaptation are deferred to Phase 2.

---

## 2. Scope

### In scope

1. Remove **YYText** from the project (Pod, source files, Podfile patch hook).
2. Remove **Texture (AsyncDisplayKit)** from the project (Pod, source files, related imports, Podfile patch hook).
3. Rewrite **`AFNManager.m`** on top of `NSURLSession`; remove **AFNetworking** Pod and its Podfile patch hook. `AFNManager.h` API remains byte-for-byte unchanged.

### Out of scope

- HBDNavigationBar removal — Phase 2.
- iOS 26 Liquid Glass adaptation — Phase 2; Phase 1 introduces **no UI changes**.
- Modernising `AFNManager`'s public API — kept fully backward-compatible, callers do not change.
- Replacing MJExtension — not on the user's list; `APPResult` continues to use `mj_objectWithKeyValues:`.
- New networking features (request signing, encryption, 4xx/5xx error code refinement) — preserve current error semantics exactly.
- Adding a unit-test target — the project has none, this phase does not introduce one.

### Validation strategy

The project has no test target. Phase 1 is verified by **manual regression** of the endpoints listed in §6. UI is unchanged, so no visual regression matrix is required.

---

## 3. Architecture — `AFNManager` on NSURLSession

`AFNManager.h` exposes three class methods today; all three keep the exact same signature:

```objc
+ (void)POST:(NSString *)url params:(NSDictionary *)params
    complete:(AFNManagerCompleteBlock)complete;

+ (void)POST:(NSString *)url params:(NSDictionary *)params
    progress:(AFNManagerProgressBlock)progress
    complete:(AFNManagerCompleteBlock)complete;

+ (void)POST:(NSString *)url params:(NSDictionary *)params
      images:(NSArray<UIImage *> *)images
    progress:(AFNManagerProgressBlock)progress
    complete:(AFNManagerCompleteBlock)complete;
```

### 3.1 Internal structure

```
AFNManager (public class — class-method facade, header unchanged)
  + POST:params:complete:                 ─┐
  + POST:params:progress:complete:         │  delegate to private singleton
  + POST:params:images:progress:complete:  ─┘

AFNManager (private singleton, conforms to NSURLSessionTaskDelegate)
  - NSURLSession *session                  ── created once with self as delegate
  - NSMapTable<NSURLSessionTask *,
               AFNManagerProgressBlock> progressBlocks
  - NSLock *progressLock                   ── serialises map access
```

The class method facade is preserved so all 21 call sites stay untouched. The singleton owns the session and the progress-block map.

### 3.2 Session configuration

```objc
NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
cfg.timeoutIntervalForRequest  = 30.0;
cfg.timeoutIntervalForResource = 60.0;
cfg.URLCache = nil;                     // match current AFN behaviour (no URL cache)
session = [NSURLSession sessionWithConfiguration:cfg
                                        delegate:self
                                   delegateQueue:nil];
```

Cannot use `[NSURLSession sharedSession]` — it does not accept a delegate, so upload-progress callbacks would be impossible.

### 3.3 Plain JSON POST

```
+ POST:url params:params progress:p complete:c
↓
build NSMutableURLRequest:
    method        = POST
    Content-Type  = application/json
    Authorization = [UserInfo getAuthorizationToken]    (if non-nil)
    app_id        = 638c2977f1b24ba0
    HTTPBody      = NSJSONSerialization dataWithJSONObject:params

dataTask = [session dataTaskWithRequest:req
                       completionHandler:^(data, response, error){
                           [self handleResponse:response data:data error:error
                                       complete:c
                                          forTask:dataTask];
                       }]
if (p) [progressBlocks setObject:p forKey:dataTask under lock]
[dataTask resume]
```

### 3.4 Multipart upload

Hand-rolled multipart body (≈ 30 lines):

```
boundary       = "Boundary-<NSUUID>"
Content-Type   = multipart/form-data; boundary=<boundary>

NSMutableData body
for each (k, v) in params:
    --<boundary>\r\n
    Content-Disposition: form-data; name="<k>"\r\n\r\n
    <stringForValue(v)> as UTF-8\r\n

for each (i, image) in images:
    NSData *data = UIImagePNGRepresentation(image)
        ?: UIImageJPEGRepresentation(image, 1.0)
    if (data == nil) continue;                          // match current behaviour
    --<boundary>\r\n
    Content-Disposition: form-data; name="file"; filename="image<i>"\r\n
    Content-Type: image/png\r\n\r\n
    <data>\r\n

--<boundary>--\r\n

uploadTask = [session uploadTaskWithRequest:req fromData:body
                          completionHandler:^...]
[progressBlocks setObject:progressBlock forKey:uploadTask under lock]
[uploadTask resume]
```

`stringForValue:` coerces non-string values via `[NSString stringWithFormat:@"%@", v]`.

### 3.5 Upload-progress delegate

```objc
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)total
  totalBytesExpectedToSend:(int64_t)expected
{
    [_progressLock lock];
    AFNManagerProgressBlock block = [_progressBlocks objectForKey:task];
    [_progressLock unlock];
    if (block) {
        CGFloat pct = (expected > 0) ? (CGFloat)total / expected : 0;
        dispatch_async(dispatch_get_main_queue(), ^{
            block(total, expected, pct);
        });
    }
}
```

### 3.6 Unified response handling

The completion handler attached to every task funnels into `handleResponse:data:error:complete:forTask:`, which mirrors the current `AFNManager.m` behaviour:

```
1) Refresh Authorization
   if response is NSHTTPURLResponse and headers contain "Authorization":
       [UserInfo saveAuthorizationToken:newToken]
       [UserInfo saveAuthorizationTimestamp]

2) Failure path
   if (error != nil):
       APPResult *r       = [APPResult new]
       r.status           = HttpStatusFail
       r.cache            = CacheStatusFail
       r.msg              = @"请求失败"
       dispatch main: complete(r)
       cleanup progress entry
       return

3) JSON decode → APPResult (keep MJExtension call)
   id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil]
   APPResult *r = [APPResult mj_objectWithKeyValues:obj]

4) Token expired
   if (r.code == TOKEN_EXPIRED):
       dispatch main: post MINE_TOKEN_EXPIRED
       cleanup progress entry
       return                       // do NOT call complete: — match current behaviour

5) Success path
   r.status = HttpStatusSuccess
   r.cache  = CacheStatusSuccess
   dispatch main: complete(r)
   cleanup progress entry
```

### 3.7 Threading guarantees

- All `complete:` and `progress:` blocks run on the main queue (current AFNetworking semantics — preserves caller code such as `[self showProgressHUD]` without changes).
- All `_progressBlocks` reads/writes go through `_progressLock`, isolating delegate-thread access from caller-thread access.

---

## 4. File-level diffs

### 4.1 Commit 1 — `chore: remove unused YYText dependency`

| Op | Path |
|---|---|
| DELETE | `bookkeeping/bookkeeping/Classes/Categorys/YYLabel/YYLabel+Extension.h` |
| DELETE | `bookkeeping/bookkeeping/Classes/Categorys/YYLabel/YYLabel+Extension.m` |
| DELETE | `bookkeeping/bookkeeping/Classes/Categorys/YYLabel/` (and any `.DS_Store`) |
| MODIFY | `bookkeeping/Podfile` — remove `pod 'YYText', '1.0.7'`; remove `'Pods/YYText/YYText/Component/YYTextLayout.m'` from `chained_cmp_patch_targets` |
| MODIFY | `bookkeeping/bookkeeping.xcodeproj/project.pbxproj` — remove the 5 `YYLabel+Extension` references (PBXBuildFile, 2× PBXFileReference, PBXGroup, Sources phase) |
| AUTO | `Podfile.lock`, `Pods/Manifest.lock`, `Pods/Pods.xcodeproj/project.pbxproj` regenerated by `pod install`; `Pods/YYText/` removed |

Neither `KKPrefixHeader.pch` nor `Common.h` requires changes — no file in either of them imports `YYLabel+Extension`.

### 4.2 Commit 2 — `chore: remove unused Texture (AsyncDisplayKit) dependency`

| Op | Path |
|---|---|
| DELETE | `bookkeeping/bookkeeping/Classes/Base/controller/ASBaseViewController.h` |
| DELETE | `bookkeeping/bookkeeping/Classes/Base/controller/ASBaseViewController.m` |
| DELETE | `bookkeeping/bookkeeping/Classes/Base/view/ASBaseTableCell.h` |
| DELETE | `bookkeeping/bookkeeping/Classes/Base/view/ASBaseTableCell.m` |
| MODIFY | `bookkeeping/bookkeeping/Classes/Base/controller/BaseNavigationController.m` — remove `#import <AsyncDisplayKit/AsyncDisplayKit.h>` (line 7) |
| MODIFY | `bookkeeping/bookkeeping/Common.h` — remove `#import "ASBaseViewController.h"` (line 42) |
| MODIFY | `bookkeeping/Podfile` — remove `pod 'Texture', '3.1.0'`; remove `'Pods/Texture/Source/TextExperiment/Component/ASTextLayout.mm'` from `chained_cmp_patch_targets` |
| MODIFY | `bookkeeping/bookkeeping.xcodeproj/project.pbxproj` — remove ~10 `ASBase*` references |
| AUTO | `Podfile.lock`, `Pods/Manifest.lock`, `Pods/Pods.xcodeproj/project.pbxproj`, `Pods/Texture/` removed |

### 4.3 Commit 3 — `refactor: rewrite AFNManager with NSURLSession`

| Op | Path |
|---|---|
| MODIFY | `bookkeeping/bookkeeping/Classes/Network/AFNManager.m` — full rewrite per §3 (≈ 200 LoC) |
| MODIFY | `bookkeeping/Podfile` — remove `pod 'AFNetworking', '4.0.1'`; remove the entire `afn_private_header_targets` patch block |
| AUTO | `Podfile.lock`, `Pods/Manifest.lock`, `Pods/Pods.xcodeproj/project.pbxproj`, `Pods/AFNetworking/` removed |

Untouched: `AFNManager.h`, `APPResult.{h,m}`, `APPViewRequest.{h,m}`, `UIView+APPViewRequest.{h,m}`, `UIViewController+APPViewRequest.{h,m}`, all 21 caller controllers, `Common.h`, `KKPrefixHeader.pch`.

### 4.4 Net Podfile reduction

- Three pod lines removed: `YYText`, `Texture`, `AFNetworking`.
- ~30 lines of `post_install` patch code removed.
- Total dependencies: 18 → 15.
- `BookMonth` widget Podfile block (`pod 'MJExtension'`) untouched — not affected by any Phase 1 change.

---

## 5. Migration sequence & validation

Each commit lands on `master` independently. Each is a self-contained, bisectable, revertable unit.

### 5.1 Commit 1 — Remove YYText

**Build validation**
1. `cd bookkeeping && pod install`
2. `xcodebuild -workspace bookkeeping.xcworkspace -scheme bookkeeping -configuration Debug -sdk iphonesimulator build` succeeds.
3. App launches in the simulator, reaches home or login screen.

**Functional validation** — none required. `YYLabel+Extension` was orphan code.

**Rollback** — `git revert <commit-1>` then `pod install`. YYText 1.0.7 returns; the Podfile chained-comparison patch hook re-engages because revert restores it.

### 5.2 Commit 2 — Remove Texture

**Build validation** — same as 5.1; `Pods/Texture/` is gone after `pod install`.

**Functional validation**
- Home tab: scroll the list, confirm `BaseTableView` rendering is intact.
- Push at least one secondary screen and pop back — confirms `BaseNavigationController` works without the AsyncDisplayKit import.

**Rollback** — `git revert <commit-2>` then `pod install`.

### 5.3 Commit 3 — Rewrite AFNManager

This is the only Phase 1 commit with business-regression risk.

#### Endpoint regression matrix (all must pass)

| # | Path | Endpoint | Verify |
|---|---|---|---|
| 1 | App launch sync | `allBookListRequest` | Home shows current month's records |
| 2 | SMS login | `userSmsCodeRequest` → `userLoginRequest` | Reaches home |
| 3 | Password login | `userLoginRequest` | Reaches home |
| 4 | Logout | `userLogoutRequest` | Returns to login screen |
| 5 | Change password | `ChangePassRequest` | Success toast |
| 6 | Add booking | `bookDetailSaveRequest` | New row appears immediately |
| 7 | Edit booking | `bookDetailUpdateRequest` | Field change persists |
| 8 | Delete booking | `bookDetailDeleteRequest` | Row removed |
| 9 | Charts | `getBookGroupRequest` | Chart data renders |
| 10 | Add category | `AddInsertCategoryListRequest` | New category appears |
| 11 | Delete category | `RemoveInsertCategoryListRequest` | Category removed |
| 12 | User info | `userInfoRequest` | Profile renders |
| 13 | Edit user info | `updateUserInfoRequest` | Change persists |
| 14 | **Avatar upload (multipart)** | `uploadAvatarRequest` | Avatar updates; progress callback on main thread; PNG → JPEG fallback works |
| 15 | Delete account | `DeleteAccountRequest` | Logs out |
| 16 | **Token expired** | (force expiry server-side or wait) | `MINE_TOKEN_EXPIRED` notification fires; session cleared; redirected to login; no `complete:` invocation |

#### Cross-cutting validation

- **Authorization auto-refresh** — log in, then on any subsequent request whose response carries an `Authorization` header, observe `UserInfo` writing the new token and the next request sending the updated token.
- **`app_id` header** — verify (e.g., via Charles / Proxyman) that every request carries `app_id: 638c2977f1b24ba0`.
- **Failure fallback** — toggle airplane mode, fire any request, confirm `complete:` receives `HttpStatusFail` + `msg = "请求失败"` and the HUD dismisses.
- **Callback thread** — set a breakpoint in any `complete:` block and confirm `[NSThread isMainThread] == YES`.

#### Real-device coverage requirement

Tests #14 (avatar upload) and #16 (token expired) must run on at least one physical device. Other endpoints may stay on simulator.

#### What must not regress

- Any UI behaviour (Phase 1 does not touch UI).
- App launch time / memory (expected to improve slightly after Texture removal).

#### Rollback

```bash
git revert <commit-3>
cd bookkeeping && pod install
```

AFNetworking 4.0.1 returns; the Podfile post-install hook re-applies the `<netinet6/in6.h>` patches automatically. All caller code is untouched, so revert is side-effect-free.

### 5.4 Whole-phase rollback

```bash
git revert <commit-3> <commit-2> <commit-1>
cd bookkeeping && pod install
```

Restores the project to the pre-Phase-1 state, including all Pod patches.

---

## 6. Risks (with mitigations)

**R1. Multipart edge cases** — image data nil after both PNG and JPEG; non-string values in `params`.
*Mitigation:* `if (data == nil) continue;` for failed image encodings; `stringForValue:` coercion for params. Verified via test #14.

**R2. Token-expired contract** — current behaviour posts the notification and **does not** invoke `complete:`. Misfiring `complete:` could cause duplicate HUDs or double redirects.
*Mitigation:* `handleResponse:` returns immediately after posting the notification; explicit code comment marks this contract.

**R3. Manual `xcodeproj` editing** — removing 5 (commit 1) + ~10 (commit 2) entries by hand risks misedits.
*Mitigation:* For each deletion, grep the file's UUID to confirm zero remaining references; run a full `xcodebuild build` before committing. If more than 4 misedits occur, fall back to deleting the files via Xcode's "Move to Trash" UI (lets Xcode maintain the pbxproj).

**R4. Stale `Pods/` cache** — old framework artefacts leftover after Pod removal.
*Mitigation:* If anything looks off, `rm -rf Pods/ Podfile.lock` and re-run `pod install`. CocoaPods is idempotent.

**R5. BookMonth widget impact** — confirmed not affected; widget Podfile block only depends on `MJExtension`.

**R6. Simulator vs. device** — multipart networking and certificate handling can differ. Tests #14 and #16 are required on a real device.

---

## 7. Resolved defaults

| ID | Question | Decision |
|---|---|---|
| Q1 | NSURLSession `timeoutIntervalForRequest` | **30 s** |
| Q2 | Remove empty `Classes/Categorys/YYLabel/` directory | **Yes** (commit 1) |
| Q3 | Enable `NSURLCache` in the new session | **No** (match current AFN behaviour) |
| Q4 | 4xx/5xx error-code refinement in this phase | **Defer** (preserve current `HttpStatusFail` + `请求失败` semantics) |

---

## 8. After Phase 1

Once Phase 1 is merged and verified, Phase 2 can be brainstormed independently. Phase 2 covers HBDNavigationBar removal + iOS 26 Liquid Glass adaptation, and is expected to involve substantial design work because of HBD's transparent / animated nav-bar behaviour and the way the app's 24 controllers depend on it.
