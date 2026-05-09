//
//  BaseViewController.m
//  iOS
//
//  Created by RY on 2018/3/19.
//  Copyright © 2018年 KK. All rights reserved.
//

#import "BaseViewController.h"

#pragma mark - 声明
@interface BaseViewController () <UIGestureRecognizerDelegate>
@end

#pragma mark - 实现
@implementation BaseViewController

#pragma mark - 初始化
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController.interactivePopGestureRecognizer setEnabled:YES];
    [self.view setBackgroundColor:kColor_BG];
    self.navigationItem.backButtonTitle = KKLocalized(@"返回");
}

#pragma mark - 系统
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:self.prefersNavigationBarHidden
                                             animated:animated];

    // When the navigation bar is hidden, UINavigationController disables its
    // interactivePopGestureRecognizer by default — leaving the user with no
    // way back if the page itself doesn't supply one. Restore the gesture for
    // non-root pushed controllers; the delegate guard below prevents the
    // gesture from firing on the stack root (which would crash).
    if (self.prefersNavigationBarHidden) {
        UIGestureRecognizer *gesture = self.navigationController.interactivePopGestureRecognizer;
        gesture.delegate = self;
        gesture.enabled = (self.navigationController.viewControllers.count > 1);
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return self.navigationController.viewControllers.count > 1;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
