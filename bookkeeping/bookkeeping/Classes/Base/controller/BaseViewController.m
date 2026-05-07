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
