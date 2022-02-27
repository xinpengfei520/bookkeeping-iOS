/**
 * 系统配置
 * @author 郑业强 2018-12-16 创建文件
 */

#import "AppDelegate.h"
#import <Bugly/Bugly.h>

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
    // Bugly
    [Bugly startWithAppId:@"0025184dd7"];
    
    // 注册通知
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            NSLog(@"completionHandler granted -> %d",granted);
        }];
        [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            NSLog(@"getNotificationSettings: %@", settings);
        }];
    }
    
    return YES;
}

// 根控制器
- (void)makeRootController {
    [self setWindow:[[UIWindow alloc] initWithFrame:SCREEN_BOUNDS]];
    [self.window setBackgroundColor:[UIColor whiteColor]];
    [self.window setRootViewController:[[BaseTabBarController alloc] init]];
    [self.window makeKeyAndVisible];
}

// 配置
- (void)systemConfig {
    [[UITextField appearance] setTintColor:kColor_Main_Color];
    // 设置导航栏按钮颜色
    [[UINavigationBar appearance] setTintColor:UIColor.whiteColor];
}

// 支持所有iOS系统
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {

    // 记一笔
    if ([url.absoluteString isEqualToString:@"kbook://month"]) {
        BaseTabBarController *tab = (BaseTabBarController *)[UIApplication sharedApplication].keyWindow.rootViewController;
        BOOL condition1 = [tab isKindOfClass:[BaseTabBarController class]];
        BOOL condition2 = ![[UIViewController getCurrentVC] isKindOfClass:[BKCController class]];
        if (condition1 && condition2) {
            BKCController *vc = [[BKCController alloc] init];
            UIViewController *current = [UIViewController getCurrentVC];
            if (current.presentedViewController) {
                [current.navigationController pushViewController:vc animated:true];
            } else {
                BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController:vc];
                [tab presentViewController:nav animated:true completion:^{
                    
                }];
            }
        }
        return YES;
    }
    // 记账完成
    else if ([url.absoluteString isEqualToString:@"kbook://book"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NOT_BOOK_COMPLETE object:nil];
    }
    return YES;
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
