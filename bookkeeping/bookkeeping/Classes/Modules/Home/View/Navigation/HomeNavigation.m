//
//  HomeNavigation.m
//  bookkeeping
//
//  Created by 郑业强 on 2019/1/6.
//  Copyright © 2019年 kk. All rights reserved.
//  2026-08-04 XIB → 代码布局（Batch 7）
//

#import "HomeNavigation.h"
#import <Masonry/Masonry.h>

#pragma mark - 实现
@implementation HomeNavigation

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

// 原 XIB：菜单按钮(左 16) + 搜索按钮(右 -20)，都在 centerY+20（状态栏下方的内容区）
- (void)buildSubviews {
    _mineButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_mineButton setImage:[UIImage imageNamed:@"icon_menu"] forState:UIControlStateNormal];
    [self addSubview:_mineButton];

    _statisticsBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_statisticsBtn setImage:[UIImage imageNamed:@"icon_search"] forState:UIControlStateNormal];
    [self addSubview:_statisticsBtn];

    [_mineButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(16);
        make.centerY.equalTo(self).offset(20);
    }];
    [_statisticsBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-20);
        make.centerY.equalTo(self).offset(20);
    }];
}

- (void)initUI {
    [self setBackgroundColor:kColor_Main_Color];
}


@end
