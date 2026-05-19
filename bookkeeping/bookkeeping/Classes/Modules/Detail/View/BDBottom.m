//
//  BDBottom.m (code-only — converted from BDBottom.xib)
//  bookkeeping
//
//  Created by 郑业强 on 2019/1/6.
//  Copyright © 2019年 kk. All rights reserved.
//

#import "BDBottom.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface BDBottom()

@property (nonatomic, strong) UIButton *editButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIView *topLine;
@property (nonatomic, strong) UIView *splitLine;

@end


#pragma mark - 实现
@implementation BDBottom

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
        [self initUI];
    }
    return self;
}

- (void)buildSubviews {
    _topLine = [[UIView alloc] init];
    [self addSubview:_topLine];

    _splitLine = [[UIView alloc] init];
    [self addSubview:_splitLine];

    _editButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_editButton addTarget:self action:@selector(editBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_editButton];

    _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_deleteButton addTarget:self action:@selector(delBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_deleteButton];

    [_topLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(self);
        make.height.equalTo(@1);
    }];
    [_editButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self);
        make.top.equalTo(self->_topLine.mas_bottom);
        // editConstraintB 在 initUI 里被设成 SafeAreaBottomHeight，原 XIB 行为是 bottom = self.bottom - SafeAreaBottomHeight
        make.bottom.equalTo(self).offset(-SafeAreaBottomHeight);
        make.right.equalTo(self.mas_centerX);
    }];
    [_deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_centerX);
        make.right.equalTo(self);
        make.top.bottom.equalTo(self->_editButton);
    }];
    [_splitLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.centerY.equalTo(self->_editButton);
        make.width.equalTo(@1);
        make.height.equalTo(@41);
    }];
}

- (void)initUI {
    [self setBackgroundColor:[UIColor systemBackgroundColor]];
    // XIB 把 line 烤成 sRGB groupTableViewBackgroundColor，dark mode 锁色；改走 systemGroupedBackgroundColor
    [self.topLine setBackgroundColor:[UIColor systemGroupedBackgroundColor]];
    [self.splitLine setBackgroundColor:[UIColor systemGroupedBackgroundColor]];

    [self.editButton setTitle:KKLocalized(@"编辑") forState:UIControlStateNormal];
    [self.editButton setTitle:KKLocalized(@"编辑") forState:UIControlStateHighlighted];
    [self.deleteButton setTitle:KKLocalized(@"删除") forState:UIControlStateNormal];
    [self.deleteButton setTitle:KKLocalized(@"删除") forState:UIControlStateHighlighted];

    [self.editButton.titleLabel setFont:[UIFont systemFontOfSize:AdjustFont(12)]];
    [self.editButton setTitleColor:kColor_Text_Black forState:UIControlStateNormal];
    [self.editButton setTitleColor:kColor_Text_Black forState:UIControlStateHighlighted];
    [self.deleteButton.titleLabel setFont:[UIFont systemFontOfSize:AdjustFont(12)]];
    [self.deleteButton setTitleColor:kColor_Text_Red forState:UIControlStateNormal];
    [self.deleteButton setTitleColor:kColor_Text_Red forState:UIControlStateHighlighted];
}

- (void)editBtnClick:(UIButton *)sender {
    [self routerEventWithName:BD_BOTTOM_CLICK data:@(0)];
}
- (void)delBtnClick:(UIButton *)sender {
    [self routerEventWithName:BD_BOTTOM_CLICK data:@(1)];
}



@end
