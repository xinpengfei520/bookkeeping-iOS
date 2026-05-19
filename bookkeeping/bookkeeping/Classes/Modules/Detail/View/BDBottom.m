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

    // splitLine 先约束；按钮挨着 splitLine 的左右边而不是 self.centerX，避免按钮覆盖
    [_splitLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.centerY.equalTo(self->_editButton);
        make.width.equalTo(@1);
        make.height.equalTo(@41);
    }];
    [_topLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(self);
        make.height.equalTo(@1);
    }];
    [_editButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self);
        make.top.equalTo(self->_topLine.mas_bottom);
        make.bottom.equalTo(self).offset(-SafeAreaBottomHeight);
        make.right.equalTo(self->_splitLine.mas_left);
    }];
    [_deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_splitLine.mas_right);
        make.right.equalTo(self);
        make.top.bottom.equalTo(self->_editButton);
    }];
}

- (void)initUI {
    [self setBackgroundColor:[UIColor systemBackgroundColor]];
    // systemGroupedBackgroundColor 在 dark 模式接近纯黑、叠在 systemBackgroundColor 上完全看不见；
    // 改用项目标准 kColor_Line_Color（light=#F5F5F5 / dark=#2C2C2E），与 SearchListHeader 等一致
    [self.topLine setBackgroundColor:kColor_Line_Color];
    [self.splitLine setBackgroundColor:kColor_Line_Color];

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
