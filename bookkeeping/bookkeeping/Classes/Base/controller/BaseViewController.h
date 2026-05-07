//
//  BaseViewController.h
//  iOS
//
//  Created by RY on 2018/3/19.
//  Copyright © 2018年 KK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseView.h"

@interface BaseViewController : UIViewController

// 是否允许侧滑返回
@property (nonatomic, assign, getter=isAllowBack) BOOL allowPanBack;

// Phase 2 native-nav contract: subclasses set this in viewDidLoad to hide the
// navigation bar on the page. See BaseViewController.viewWillAppear:.
@property (nonatomic, assign) BOOL prefersNavigationBarHidden;

// 导航栏
@property (nonatomic, strong) UIColor *navColor;

@end
