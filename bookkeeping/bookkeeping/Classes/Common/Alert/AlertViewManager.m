//
//  AlertViewManager.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/15.
//  Copyright © 2022 kk. All rights reserved.
//

#import "AlertViewManager.h"

#define RootVC [[UIApplication sharedApplication] keyWindow].rootViewController

@interface AlertViewManager () <UIActionSheetDelegate,UIAlertViewDelegate>

@property (nonatomic, copy) alertViewBlock block;
@property (nonatomic,assign) NSInteger selectBtnTag;

@end

@implementation AlertViewManager

#pragma mark - 对外方法
+(AlertViewManager *)sharedInstacne{
    static AlertViewManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

-(void)showAlert:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle viewController:(UIViewController *)vc confirm:(alertViewBlock)confirm buttonTitles:(NSString *)buttonTitles, ...{
    if (!vc) vc = RootVC;
    
    // 读取可变参数里面的titles数组
    NSMutableArray *titleArray = [[NSMutableArray alloc] initWithCapacity:0];
    va_list list;
    if(buttonTitles) {
        // 1.取得第一个参数的值(即是buttonTitles)
        [titleArray addObject:buttonTitles];
        // 2.从第2个参数开始，依此取得所有参数的值
        NSString *otherTitle;
        va_start(list, buttonTitles);
        while ((otherTitle= va_arg(list, NSString*))) {
            [titleArray addObject:otherTitle];
        }
        va_end(list);
    }
    
    [self showAlertController:title message:message cancelTitle:cancelTitle titleArray:titleArray viewController:vc confirm:confirm];
}

-(void)showSheet:(nullable NSString *)title message:(nullable NSString *)message cancelTitle:(NSString *)cancelTitle viewController:(UIViewController *)vc confirm:(alertViewBlock)confirm buttonTitles:(NSString *)buttonTitles, ...{
    if (!vc) vc = RootVC;
    // 读取可变参数里面的 titles 数组
    NSMutableArray *titleArray = [[NSMutableArray alloc] initWithCapacity:0];
    va_list list;
    if(buttonTitles) {
        // 1.取得第一个参数的值(即是buttonTitles)
        [titleArray addObject:buttonTitles];
        // 2.从第2个参数开始，依此取得所有参数的值
        NSString *otherTitle;
        va_start(list, buttonTitles);
        while ((otherTitle= va_arg(list, NSString*))) {
            [titleArray addObject:otherTitle];
        }
        va_end(list);
    }
    
    [self showSheetAlertController:title message:message cancelTitle:cancelTitle titleArray:titleArray viewController:vc confirm:confirm];
}

- (void)showSheet:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle viewController:(UIViewController *)vc confirm:(alertViewBlock)confirm buttonArray:(NSArray<NSArray *> *)buttonArray{
    if (!vc) vc = RootVC;
    
    [self showSheetAlertController:title message:message cancelTitle:cancelTitle buttonArray:buttonArray viewController:vc confirm:confirm];
}

- (void)showAlertController:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle titleArray:(NSArray *)titleArray viewController:(UIViewController *)vc
                      confirm:(alertViewBlock)confirm {
    
    UIAlertController  *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    // 下面两行代码 是修改 title颜色和字体的代码
    //    NSAttributedString *attributedMessage = [[NSAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17.0f], NSForegroundColorAttributeName:UIColorFrom16RGB(0x334455)}];
    //    [alert setValue:attributedMessage forKey:@"attributedTitle"];
    if (cancelTitle) {
        // 取消
        UIAlertAction  *cancelAction = [UIAlertAction actionWithTitle:cancelTitle  style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
            if (confirm) {
                confirm(0, action.title);
            }
            
        }];
        [alert addAction:cancelAction];
    }
    
    // 确定操作
    if (!titleArray || titleArray.count == 0) {
        UIAlertAction  *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault  handler:^(UIAlertAction * _Nonnull action) {
            if (confirm)confirm(0,action.title);
        }];
        [alert addAction:confirmAction];
    } else {
        for (NSInteger i = 0; i<titleArray.count; i++) {
            UIAlertAction  *action = [UIAlertAction actionWithTitle:titleArray[i] style:UIAlertActionStyleDefault  handler:^(UIAlertAction * _Nonnull action) {
                if (confirm)confirm(i,action.title);
            }];
            // [action setValue:UIColorFrom16RGB(0x00AE08) forKey:@"titleTextColor"]; // 此代码 可以修改按钮颜色
            [alert addAction:action];
        }
    }
    [vc presentViewController:alert animated:YES completion:nil];
}


// ActionSheet的封装(iOS8及其以后)
- (void)showSheetAlertController:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle titleArray:(NSArray *)titleArray viewController:(UIViewController *)vc confirm:(alertViewBlock)confirm {
    
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
    if (!cancelTitle) cancelTitle = @"取消";
    // 取消
    UIAlertAction  *cancelAction = [UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (confirm)confirm(cancelIndex,action.title);
    }];
    
    [sheet addAction:cancelAction];
    if (titleArray.count > 0) {
        for (NSInteger i = 0; i<titleArray.count; i++) {
            UIAlertAction  *action = [UIAlertAction actionWithTitle:titleArray[i] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if (confirm)confirm(i,action.title);
            }];
            [sheet addAction:action];
        }
    }
    
    [vc presentViewController:sheet animated:YES completion:nil];
}

- (void)showSheetAlertController:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle buttonArray:(NSArray<NSArray *> *)buttonArray viewController:(UIViewController *)vc confirm:(alertViewBlock)confirm {
    
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
    if (!cancelTitle) cancelTitle = @"取消";
    // 取消
    UIAlertAction  *cancelAction = [UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (confirm)confirm(cancelIndex,action.title);
    }];
    
    [sheet addAction:cancelAction];
    if (buttonArray.count == 2) {
        for (NSInteger i = 0; i<buttonArray[0].count; i++) {
            NSString *title = buttonArray[0][i];
            NSNumber *style = buttonArray[1][i];
            UIAlertAction  *action = [UIAlertAction actionWithTitle:title style:[style integerValue] handler:^(UIAlertAction * _Nonnull action) {
                if (confirm)confirm(i,action.title);
            }];
            [sheet addAction:action];
        }
    }
    
    [vc presentViewController:sheet animated:YES completion:nil];
}

@end
