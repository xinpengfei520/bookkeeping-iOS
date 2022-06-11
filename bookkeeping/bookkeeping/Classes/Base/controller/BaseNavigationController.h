/**
 * 导航栏
 * @author 郑业强 2018-03-19
 */

#import <UIKit/UIKit.h>
#import "HBDNavigationController.h"

@interface BaseNavigationController : HBDNavigationController

#pragma mark - 初始化
+ (instancetype)initWithRootViewController:(UIViewController *)vc;

@end
