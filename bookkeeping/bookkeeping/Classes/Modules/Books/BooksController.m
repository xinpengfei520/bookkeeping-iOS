//
//  BooksController.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/7/7.
//  Copyright © 2022 kk. All rights reserved.
//

#import "BooksController.h"
#import "BottomButton.h"
#import "AlertViewManager.h"

@interface BooksController ()

@property (nonatomic, strong) BottomButton *bottom;
@property (nonatomic, strong) NSDictionary<NSString *, NSInvocation *> *eventStrategy;

@end

@implementation BooksController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = NO;
    self.hbd_barTintColor = kColor_Main_Color;
    [self setNavTitle:@"账本"];
    [self bottom];
}

- (BottomButton *)bottom {
    if (!_bottom) {
        _bottom = [BottomButton initWithFrame:({
            CGFloat height = countcoordinatesX(50) + SafeAreaBottomHeight;
            CGFloat top = SCREEN_HEIGHT - height - NavigationBarHeight;
            CGRectMake(0, top, SCREEN_WIDTH, height);
        })];
        [_bottom setName:@"创建账本"];
        [self.view addSubview:_bottom];
    }
    _bottom.layer.shadowPath = [UIBezierPath bezierPathWithRect:_bottom.bounds].CGPath;
    return _bottom;
}

- (void)bottomClick:(id)data {
    [[AlertViewManager sharedInstacne]showSheet:nil message:nil cancelTitle:@"取消" viewController:self confirm:^(NSInteger buttonTag,NSString *buttonTitle) {
        [self createBook:buttonTag];
    } buttonTitles:@"生意账本", @"报销账本", @"公司账本", @"团队账本", @"自定义账本", nil];
}

- (void)createBook:(NSInteger)tag{
    if (tag == 0) {
        
    } else if (tag == 1) {
        
    }
}

#pragma mark - 事件
- (void)routerEventWithName:(NSString *)eventName data:(id)data {
    [self handleEventWithName:eventName data:data];
}

- (void)handleEventWithName:(NSString *)eventName data:(id)data {
    NSInvocation *invocation = self.eventStrategy[eventName];
    [invocation setArgument:&data atIndex:2];
    [invocation invoke];
    [super routerEventWithName:eventName data:data];
}

- (NSDictionary<NSString *, NSInvocation *> *)eventStrategy {
    if (!_eventStrategy) {
        _eventStrategy = @{
            CATEGORY_BTN_CLICK: [self createInvocationWithSelector:@selector(bottomClick:)],
        };
    }
    return _eventStrategy;
}


@end
