//
//  BaseTabBarController.h
//
//  Created by RY on 2018/3/19.
//  Copyright © 2018年 KK. All rights reserved.
//
//  UITabBarController - 选项卡控制器，顾名思义，选项卡控制器在屏幕底部显示一系列「选项卡」，这些选项卡表示为图标和文本，
//  用户触摸它们将在不同的场景间切换。和 UINavigationController 类似，UITabBarController 也可以用来控制多个页面导航，
//  用户可以在多个视图控制器之间切换，并可以定制屏幕底部的选项卡栏。
//  借助屏幕底部的选项卡栏，UITabBarController 不必像 UINavigationController 那样以栈的方式推入和推出视图，
//  而是建立一系列的控制器（这些控制器可以是 UIViewController、UINavigationController、UITableViewController等）
//  并将它们添加到选项卡栏，使每个选项卡对应一个控制器。每个场景都呈现了应用程序的一项功能，或是提供了一种查看应用程序的独特方式。
//  UITabBarController 是 iOS 中很常用的一个 viewController,例如系统的闹钟程序等，QQ 也是用的 UITabBarController。
//  UITabBarController 通常作为整个程序的 rootViewController，而且不能添加到别的 container viewController中。
//

#import <UIKit/UIKit.h>

@interface BaseTabBarController : UITabBarController

@property (nonatomic, assign) NSInteger index;

- (void)hideTabbar:(BOOL)hidden;

@end
