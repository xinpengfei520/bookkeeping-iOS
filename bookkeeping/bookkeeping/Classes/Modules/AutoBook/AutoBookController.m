//
//  AutoBookController.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/7/7.
//  Copyright © 2022 kk. All rights reserved.
//

#import "AutoBookController.h"
#import "BottomButton.h"
#import "CA_EVENT.h"

@interface AutoBookController ()

@property (nonatomic, strong) BottomButton *bottom;
@property (nonatomic, strong) NSDictionary<NSString *, NSInvocation *> *eventStrategy;

@end

@implementation AutoBookController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = NO;
    self.hbd_barTintColor = kColor_Main_Color;
    [self setNavTitle:@"定时记账"];
    [self bottom];
}

- (BottomButton *)bottom {
    if (!_bottom) {
        _bottom = [BottomButton initWithFrame:({
            CGFloat height = countcoordinatesX(50) + SafeAreaBottomHeight;
            CGFloat top = SCREEN_HEIGHT - height - NavigationBarHeight;
            CGRectMake(0, top, SCREEN_WIDTH, height);
        })];
        [_bottom setName:@"+添加定时记账"];
        [self.view addSubview:_bottom];
    }
    _bottom.layer.shadowPath = [UIBezierPath bezierPathWithRect:_bottom.bounds].CGPath;
    return _bottom;
}

- (void)bottomClick:(id)data {
    
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
