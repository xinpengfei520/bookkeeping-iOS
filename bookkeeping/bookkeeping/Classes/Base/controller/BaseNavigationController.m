/**
 * 导航栏
 * @author 郑业强 2018-03-19
 */

#import "BaseNavigationController.h"

#pragma mark - 声明
@interface BaseNavigationController ()

@end

#pragma mark - 实现
@implementation BaseNavigationController


#pragma mark - 初始化
+ (instancetype)initWithRootViewController:(UIViewController *)vc {
    BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController:vc];
    return nav;
}
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    viewController.hidesBottomBarWhenPushed = (self.viewControllers.count == 1);
    [super pushViewController:viewController animated:animated];
}

@end

