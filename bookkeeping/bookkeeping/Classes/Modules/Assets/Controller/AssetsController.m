//
//  AssetsController.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/7/7.
//  Copyright © 2022 kk. All rights reserved.
//

#import "AssetsController.h"
#import "BottomButton.h"
#import "AssetsHeader.h"
#import "CA_EVENT.h"

@interface AssetsController ()

@property (nonatomic, strong) AssetsHeader *header;
@property (nonatomic, strong) BottomButton *bottom;
@property (nonatomic, strong) NSDictionary<NSString *, NSInvocation *> *eventStrategy;

@end

@implementation AssetsController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = NO;
    self.hbd_barTintColor = kColor_Main_Color;
    [self setNavTitle:@"资产"];
    [self header];
    [self bottom];
}


- (AssetsHeader *)header {
    if (!_header) {
        _header = [AssetsHeader loadFirstNib:CGRectMake(0, 0, SCREEN_WIDTH, countcoordinatesX(64))];
        [self.view addSubview:_header];
    }
    return _header;
}

- (BottomButton *)bottom {
    if (!_bottom) {
        _bottom = [BottomButton initWithFrame:({
            CGFloat height = countcoordinatesX(50) + SafeAreaBottomHeight;
            CGFloat top = SCREEN_HEIGHT - height - NavigationBarHeight;
            CGRectMake(0, top, SCREEN_WIDTH, height);
        })];
        [_bottom setName:@"+添加资产"];
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