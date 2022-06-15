//
//  AlertViewManager.h
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/15.
//  Copyright © 2022 kk. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^alertViewBlock)(NSInteger buttonTag,NSString *buttonTitle);

static NSInteger const cancelIndex = -1;

@interface AlertViewManager : NSObject

/**
 单例模式
 @return 单例对象
 */
+(AlertViewManager *)sharedInstacne;

/**
 *  创建提示框(Alert 可变参数版)
 *
 *  @param title        标题
 *  @param message      提示内容
 *  @param cancelTitle  取消按钮(无操作,为nil则只显示一个按钮)
 *  @param vc           VC iOS8及其以后会用到
 *  @param confirm      点击按钮的回调(取消按钮的Index是cancelIndex -1)
 *  @param buttonTitles 按钮(为nil,默认为"确定",传参数时必须以nil结尾，否则会崩溃)
 */
- (void)showAlert:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle viewController:(UIViewController *)vc confirm:(alertViewBlock)confirm buttonTitles:(NSString *)buttonTitles, ... NS_REQUIRES_NIL_TERMINATION;

/**
 *  创建菜单(Sheet 可变参数版)
 *
 *  @param title        标题
 *  @param message      提示内容
 *  @param cancelTitle  取消按钮(无操作,为nil则只显示一个按钮)
 *  @param vc           VC
 *  @param confirm      点击按钮的回调(取消按钮的Index是cancelIndex -1)
 *  @param buttonTitles 按钮(为nil,默认为"确定",传参数时必须以nil结尾，否则会崩溃)
 */
- (void)showSheet:(nullable NSString *)title message:(nullable NSString *)message cancelTitle:(NSString *)cancelTitle viewController:(UIViewController *)vc confirm:(alertViewBlock)confirm buttonTitles:(NSString *)buttonTitles, ... NS_REQUIRES_NIL_TERMINATION;

/**
 *  创建指定样式的菜单(Sheet 字典参数版)
 *
 *  @param title        标题
 *  @param message      提示内容
 *  @param cancelTitle  取消按钮(无操作,为nil则只显示一个按钮)
 *  @param vc           VC
 *  @param confirm      点击按钮的回调(取消按钮的Index是cancelIndex -1)
 *  @param buttonArray 按钮二维数组，array[0] 存放 title 数组, array[1] 存放 style 数组，使用 NSArray可以保证添加的顺序，而字典不能保证
 */
- (void)showSheet:(nullable NSString *)title message:(nullable NSString *)message cancelTitle:(NSString *)cancelTitle viewController:(UIViewController *)vc confirm:(alertViewBlock)confirm buttonArray:(NSArray<NSArray *> *)buttonArray;

@end

NS_ASSUME_NONNULL_END
