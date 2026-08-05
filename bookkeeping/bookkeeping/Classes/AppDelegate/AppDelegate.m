/**
 * 系统配置
 * @author 郑业强 2018-12-16 创建文件
 */

#import "AppDelegate.h"
// Bugly 官方 framework 没有 arm64-simulator 切片，模拟器构建不链接它
// （Podfile post_install 会把 -framework Bugly 从模拟器的 ldflags 里剔掉），
// 代码里也要同步用 TARGET_OS_SIMULATOR 挡住，否则链接报错。
#if !TARGET_OS_SIMULATOR
#import <Bugly/Bugly.h>
#endif

#pragma mark - 声明
@interface AppDelegate ()

@end


#pragma mark - 实现
@implementation AppDelegate

// TODO: 1、数据存到iCloud；2、发送本地通知提醒；3、Face ID解锁；
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 根控制器
    [self makeRootController];
    // 系统配置
    [self systemConfig];
    // Bugly（模拟器上不可用，见文件顶部说明；崩溃采集本来也只关心真机）
#if !TARGET_OS_SIMULATOR
    [Bugly startWithAppId:@"0025184dd7"];
#endif

    // 刷新 App Shortcuts 短语注册（短语列表变更后老安装不会自动更新）
    [NSClassFromString(@"KKAppShortcutsRefresher") performSelector:@selector(refresh)];

#if DEBUG
    // 仅模拟器调试用：`simctl launch --setenv KK_DEBUG_OPEN book <bundle id>` 直接弹记账页
    // 并展开键盘。simctl openurl 打自定义 scheme 会被系统"在 xx 中打开?"弹窗拦住，
    // 无法自动化截图/联调，所以留这个环境变量后门（Release 编译不进包）。
    NSString *debugOpen = NSProcessInfo.processInfo.environment[@"KK_DEBUG_OPEN"];
    if ([debugOpen isEqualToString:@"book"]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            BookController *vc = [[BookController alloc] init];
            BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController:vc];
            nav.modalPresentationStyle = UIModalPresentationCurrentContext;
            UIViewController *top = self.window.rootViewController;
            while (top.presentedViewController) top = top.presentedViewController;
            [top presentViewController:nav animated:YES completion:^{
                // KVC 取私有 keyboard 属性直接展示，便于截图验证键盘布局
                id keyboard = [vc valueForKey:@"keyboard"];
                if ([keyboard respondsToSelector:@selector(show)]) {
                    [keyboard performSelector:@selector(show)];
                }
            }];
        });
    }
    // KK_DEBUG_OPEN=siri 直开 Siri 捷径管理页
    else if ([debugOpen isEqualToString:@"siri"]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self presentModalController:[[SiriShortcutsController alloc] init]];
        });
    }
    // KK_DEBUG_OPEN=rate 直开今日汇率页（验证走势布局）
    else if ([debugOpen isEqualToString:@"rate"]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            RateController *vc = [[RateController alloc] init];
            BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController:vc];
            UIViewController *top = self.window.rootViewController;
            while (top.presentedViewController) top = top.presentedViewController;
            [top presentViewController:nav animated:YES completion:nil];
        });
    }
#endif
    
    // 注册通知
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            KKLog(@"completionHandler granted -> %d",granted);
        }];
        [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            KKLog(@"getNotificationSettings: %@", settings);
        }];
    }
    
    return YES;
}

// 根控制器
- (void)makeRootController {
    [self setWindow:[[UIWindow alloc] initWithFrame:SCREEN_BOUNDS]];
    [self.window setBackgroundColor:[UIColor systemBackgroundColor]];

    // 应用用户的深色模式偏好（nil = 跟随系统）
    [KKTheme applyToWindow:self.window];

    BOOL isEn = [[KKI18n effectiveLanguageCode] isEqualToString:KKLanguageCodeEnglish];

    // Tab 0 — 记账（首页）
    HomeController *homeVC = [[HomeController alloc] init];
    BaseNavigationController *homeNav = [[BaseNavigationController alloc] initWithRootViewController:homeVC];
    homeNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:(isEn ? @"Records" : @"记账")
                                                       image:[UIImage systemImageNamed:@"house"]
                                               selectedImage:[UIImage systemImageNamed:@"house.fill"]];

    // Tab 1 — 我的
    MineController *mineVC = [[MineController alloc] init];
    BaseNavigationController *mineNav = [[BaseNavigationController alloc] initWithRootViewController:mineVC];
    mineNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:KKLocalized(@"我的")
                                                       image:[UIImage systemImageNamed:@"person"]
                                               selectedImage:[UIImage systemImageNamed:@"person.fill"]];

    UITabBarController *tab = [[UITabBarController alloc] init];
    tab.viewControllers = @[homeNav, mineNav];
    // 选中态用品牌绿（kColor_Main_Color）。iOS 26 启用 Liquid Glass 后这里
    // 会被系统外观自动接管，颜色会保持品牌色但材质变玻璃。如果 Info.plist
    // UIDesignRequiresCompatibility=YES 还在（当前如此），tab bar 仍然是
    // iOS 25 风格半透明灰底；要切到 Liquid Glass 把 plist 那个 key 删了即可。
    tab.tabBar.tintColor = kColor_Main_Color;

    [self.window setRootViewController:tab];
    [self.window makeKeyAndVisible];
}

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
    // translucent = NO 让 self.view 起点在导航条下方（不延伸到 bar 后），匹配项目里
    // 既有的两种 layout pattern：(a) 部分页面用 offset(NavigationBarHeight + 20)
    // 作为 bar 下方的 padding；(b) 部分页面直接 offset(20)。两种都假设 view 起点
    // 已经在 bar 之下——HBD 时代由 HBD 自己保证；Phase 2 由这一行接管。
    [[UINavigationBar appearance] setTranslucent:NO];

    [[UITextField appearance] setTintColor:kColor_Main_Color];
}

// 支持所有iOS系统
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {

    // 记一笔（widget 触发）
    if ([url.absoluteString isEqualToString:@"kbook://month"]) {
        [self presentBookController];
        return YES;
    }
    // 记账完成
    else if ([url.absoluteString isEqualToString:@"kbook://book"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_BOOK_ADD object:nil];
    }
    return YES;
}

#pragma mark - Siri 捷径（NSUserActivity 路由，见 SiriShortcutsController）
- (BOOL)application:(UIApplication *)application
    continueUserActivity:(NSUserActivity *)userActivity
      restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *))restorationHandler {

    if ([userActivity.activityType isEqualToString:KKActivityTypeBook]) {
        [self presentBookController];
        return YES;
    }
    if ([userActivity.activityType isEqualToString:KKActivityTypeRate]) {
        [self presentModalController:[[RateController alloc] init]];
        return YES;
    }
    if ([userActivity.activityType isEqualToString:KKActivityTypeChart]) {
        // ChartController 自带的返回按钮走 pop，必须 push 进导航栈（模态会退不出去）
        [self pushOnHomeTab:[[ChartController alloc] init]];
        return YES;
    }
    return NO;
}

#pragma mark - 页面呈现辅助

// 记账键盘（kbook://month 与 Siri 捷径共用；未登录先弹登录）
- (void)presentBookController {
    UIViewController *current = [UIViewController getCurrentVC];
    if ([current isKindOfClass:[BookController class]]) {
        return; // 已经在记账页，不重复弹
    }

    BookController *vc = [[BookController alloc] init];
    BaseNavigationController *nav = nil;
    if ([UserInfo isLogin]) {
        nav = [[BaseNavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationCurrentContext;
    } else {
        LoginController *loginController = [[LoginController alloc] init];
        nav = [[BaseNavigationController alloc] initWithRootViewController:loginController];
    }

    // 取最顶层 VC 弹窗呈现 — root 现在是 UITabBarController，
    // 简单 [root presentViewController:] 不可靠（有 modal 已盖时会出 warning）。
    UIViewController *top = self.window.rootViewController;
    while (top.presentedViewController) top = top.presentedViewController;
    [top presentViewController:nav animated:YES completion:nil];
}

// 模态打开某个普通页面，导航栏左侧补一个关闭按钮（模态没有系统返回）
- (void)presentModalController:(UIViewController *)vc {
    vc.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                                      target:self
                                                      action:@selector(dismissTopController)];
    BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController:vc];
    UIViewController *top = self.window.rootViewController;
    while (top.presentedViewController) top = top.presentedViewController;
    [top presentViewController:nav animated:YES completion:nil];
}

- (void)dismissTopController {
    UIViewController *top = self.window.rootViewController;
    while (top.presentedViewController) top = top.presentedViewController;
    [top dismissViewControllerAnimated:YES completion:nil];
}

// 收掉所有 modal → 切到首页 tab → push（供需要导航栈返回的页面用）
- (void)pushOnHomeTab:(UIViewController *)vc {
    UIViewController *root = self.window.rootViewController;
    if (root.presentedViewController) {
        [root dismissViewControllerAnimated:NO completion:nil];
    }
    if ([root isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tab = (UITabBarController *)root;
        tab.selectedIndex = 0;
        UIViewController *selected = tab.selectedViewController;
        if ([selected isKindOfClass:[UINavigationController class]]) {
            [(UINavigationController *)selected pushViewController:vc animated:YES];
        }
    }
}

// 去后台
- (void)applicationWillResignActive:(UIApplication *)application {
    [ScreenBlurry addBlurryScreenImage];
}

// 回前台
- (void)applicationDidBecomeActive:(UIApplication *)application {
    [ScreenBlurry removeBlurryScreenImage];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
