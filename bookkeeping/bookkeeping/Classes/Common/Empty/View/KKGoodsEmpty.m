//
//  KKGoodsEmpty.m
//  imiss-ios-master
//
//  Created by 郑业强 on 2018/10/27.
//  Copyright © 2018年 kk. All rights reserved.
//  2026-08-04 XIB → 代码布局（Batch 8）：骨架屏占位（大图方块 + 白卡片里的灰条）
//

#import "KKGoodsEmpty.h"
#import <Masonry/Masonry.h>

#pragma mark - 实现
@implementation KKGoodsEmpty

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

// 原 XIB：顶部 1:1 灰色图块，下方 130pt 白卡片，卡片里 4 行灰条 + 底部一排 3 个灰条
- (void)buildSubviews {
    self.backgroundColor = kColor_BG;

    UIView *imageBlock = [[UIView alloc] init];
    imageBlock.backgroundColor = [UIColor colorWithWhite:0.843 alpha:1];
    [self addSubview:imageBlock];

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor systemBackgroundColor];
    [self addSubview:card];

    [imageBlock mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
        make.height.equalTo(imageBlock.mas_width);
    }];
    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(imageBlock.mas_bottom).offset(10);
        make.left.right.equalTo(self);
        make.height.equalTo(@130);
    }];

    // 4 行文本占位灰条（宽度 80/130/50/140，行高 14，行距 9）
    UIView *previous = nil;
    for (NSNumber *width in @[@80, @130, @50, @140]) {
        UIView *bar = [[UIView alloc] init];
        bar.backgroundColor = kColor_BG;
        [card addSubview:bar];
        UIView *anchor = previous;
        [bar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(card).offset(10);
            make.width.equalTo(width);
            make.height.equalTo(@14);
            if (anchor) {
                make.top.equalTo(anchor.mas_bottom).offset(9);
            } else {
                make.top.equalTo(card).offset(10);
            }
        }];
        previous = bar;
    }

    // 底部一排 3 个等宽灰条（左 / 中 / 右）
    UIView *left = [[UIView alloc] init];
    UIView *middle = [[UIView alloc] init];
    UIView *right = [[UIView alloc] init];
    for (UIView *bar in @[left, middle, right]) {
        bar.backgroundColor = kColor_BG;
        [card addSubview:bar];
    }
    [left mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(card).offset(10);
        make.bottom.equalTo(card).offset(-15);
        make.width.equalTo(@60);
        make.height.equalTo(@14);
    }];
    [middle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(card);
        make.centerY.width.height.equalTo(left);
    }];
    [right mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(card).offset(-10);
        make.centerY.width.height.equalTo(left);
    }];
}


#pragma mark - 动画
- (void)show {
    [self setAlpha:1];
}

- (void)hide {
    [self setAlpha:0];
}


@end
