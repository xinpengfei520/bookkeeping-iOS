//
//  BaseTabBarController.m
//  iOS
//
//  Created by RY on 2018/3/19.
//  Copyright © 2018年 KK. All rights reserved.
//  
//  UIModalPresentationFullScreen代表弹出VC时，presentedVC充满全屏，如果弹出VC的wantsFullScreenLayout
//  设置为YES的，则会填充到状态栏下边，否则不会填充到状态栏之下。
//　UIModalPresentationPageSheet代表弹出是弹出VC时，presentedVC的高度和当前屏幕高度相同，宽度和竖屏模式下
//  屏幕宽度相同，剩余未覆盖区域将会变暗并阻止用户点击，这种弹出模式下，竖屏时跟UIModalPresentationFullScreen的效果一样，
//  横屏时候两边则会留下变暗的区域。
//　UIModalPresentationFormSheet这种模式下，presented VC的高度和宽度均会小于屏幕尺寸，presented VC居中显示，四周留下变暗区域。
//　UIModalPresentationCurrentContext这种模式下，presented VC的弹出方式和presenting VC的父VC的方式相同。
//　这四种方式在iPad上面统统有效，但在iPhone和iPod touch上面系统始终已UIModalPresentationFullScreen模式显示presented VC

#import "BaseTabBarController.h"
#import "BaseTabBar.h"
#import "LAContextManager.h"

#define IS_IPHONE_X ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)

#pragma mark - 声明
@interface BaseTabBarController ()

@property (nonatomic, strong) BaseTabBar *bar;

@end


#pragma mark - 实现
@implementation BaseTabBarController


- (void)viewDidLoad {
    [super viewDidLoad];
    // 明细页面
    HomeController *home = [[HomeController alloc] init];
    [self addChildViewController:home title:@"明细" image:@"tabbar_detail_n" selImage:@"tabbar_detail_s"];
    // 记账页面
    BaseViewController *message = [[BaseViewController alloc] init];
    [self addChildViewController:message title:@"记账" image:@"tabbar_add_n" selImage:@"tabbar_add_h"];
    // 图表页面
    ChartController *sort = [[ChartController alloc] init];
    [self addChildViewController:sort title:@"图表" image:@"tabbar_chart_n" selImage:@"tabbar_chart_s"];
}

- (void)hideTabbar:(BOOL)hidden {
    [UIView animateWithDuration:.3f delay:0.f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.tabBar.top = SCREEN_HEIGHT - (hidden == YES ? 0 : TabbarHeight);
    } completion:^(BOOL finished) {
        
    }];
}

/**
 * 添加子 ViewController
 */
- (void)addChildViewController:(BaseViewController *)childVc title:(NSString *)title image:(NSString *)image selImage:(NSString *)selImage {
    static NSInteger index = 0;
    childVc.tabBarItem.title = title;
    childVc.tabBarItem.image = [[UIImage imageNamed:image] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    childVc.tabBarItem.selectedImage = [[UIImage imageNamed:selImage] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    childVc.tabBarItem.tag = index;
    childVc.navTitle = title;
    
    index++;
    
    // 让子控制器包装一个导航控制器
    BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController:childVc];
    [self addChildViewController:nav];
}


#pragma mark - set
- (void)setIndex:(NSInteger)index {
    _index = index;
    _bar.index = index;
}


#pragma mark - get
- (BaseTabBar *)bar {
    if (!_bar) {
        @weakify(self)
        for (UIView *view in self.tabBar.subviews) {
            [view removeFromSuperview];
        }
        
        _bar = [[BaseTabBar alloc] init];
        [_bar setClick:^(NSInteger index) {
            @strongify(self)
            // 记账
            if (index == 1) {
                BKCController *vc = [[BKCController alloc] init];
                BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController:vc];
                // Modal Presentation Styles（弹出风格）
                nav.modalPresentationStyle = UIModalPresentationCurrentContext;
                self.navigationController.definesPresentationContext = NO;
                [self presentViewController:nav animated:YES completion:^{
                    
                }];
            }
            else {
                // 我的
                if (index == 4) {
                    BaseNavigationController *nav = self.viewControllers[index];
                    MineController *vc = nav.viewControllers[0];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [vc.mine.table setContentOffset:CGPointZero animated:true];
                    });
                }
                [self setSelectedIndex:index];
                [self.bar setIndex:index];
            }
        }];
        [self setValue:_bar forKey:@"tabBar"];
    }
    return _bar;
}


#pragma mark - 系统
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self bar];
    // 从缓存中取出 PIN_SETTING_FACE_ID 的值，如果没有则默认为 0
    NSNumber *faceId = [NSUserDefaults objectForKey:PIN_SETTING_FACE_ID];
    if ([faceId boolValue] == true) {
        [self verifyFaceID];
    }
}

- (void)verifyFaceID {
    [LAContextManager callLAContextManagerWithController:self success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"FaceID verify success~");
        });
    } failure:^(NSError *tyError, LAContextErrorType feedType) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // @TODO
            if (tyError.code == -8) {
                // 超出TouchID尝试次数或FaceID尝试次数，已被锁
                NSLog(@"超出TouchID尝试次数或FaceID尝试次数，已被锁========");
            }
            else if (tyError.code == -7) {
                // 未开启TouchID权限(没有可用的指纹)
                NSLog(@"未开启TouchID权限(没有可用的指纹)========");
            }
            else if (tyError.code == -6) {
                if (IS_IPHONE_X) {
                    // iPhoneX 设置里面没有开启FaceID权限
                    NSLog(@"iPhoneX 设置里面没有开启FaceID权限========");
                }
                else {
                    // 非iPhoneX手机且该手机不支持TouchID(如iPhone5、iPhone4s)
                    NSLog(@"非iPhoneX手机且该手机不支持TouchID(如iPhone5、iPhone4s)========");
                }
            }
            else {
                // 其他error情况 如用户主动取消等
                NSLog(@"其他error情况 如用户主动取消等========");
            }
        });
    }];
}

@end
