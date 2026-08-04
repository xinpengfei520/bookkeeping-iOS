//
//  BDHeader.m
//  bookkeeping
//
//  Created by 郑业强 on 2019/1/5.
//  Copyright © 2019年 kk. All rights reserved.
//  2026-08-04 XIB → 代码布局（Batch 7）
//

#import "BDHeader.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface BDHeader()

@property (nonatomic, strong) UIImageView *icon;
@property (nonatomic, strong) UILabel *nameLab;
@property (nonatomic, strong) UIButton *backBtn;

@end


#pragma mark - 实现
@implementation BDHeader

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

// 原 XIB：返回按钮(40×35)左上；类别大图标居中(60pt→countcoordinatesX(60))；名称在图标下方
- (void)buildSubviews {
    _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_backBtn setImage:[UIImage imageNamed:@"icon_back_white"] forState:UIControlStateNormal];
    [self addSubview:_backBtn];

    _icon = [[UIImageView alloc] init];
    [self addSubview:_icon];

    _nameLab = [[UILabel alloc] init];
    _nameLab.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_nameLab];

    [_backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(5);
        make.left.equalTo(self).offset(20);
        make.width.equalTo(@40);
        make.height.equalTo(@35);
    }];
    [_icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self->_backBtn).offset(10);
        make.width.height.equalTo(@(countcoordinatesX(60)));
    }];
    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self);
        make.top.equalTo(self->_icon.mas_bottom).offset(10);
    }];

    [_backBtn addTarget:self action:@selector(backClick:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)initUI {
    [self setBackgroundColor:kColor_Main_Color];
    [self.nameLab setFont:[UIFont systemFontOfSize:AdjustFont(12)]];
    [self.nameLab setTextColor:kColor_Text_White];
}

#pragma mark - 点击
- (void)backClick:(UIButton *)sender {
    [self.viewController.navigationController popViewControllerAnimated:true];
}


#pragma mark - set
- (void)setModel:(BookDetailModel *)model {
    _model = model;
    BKCModel *cmodel = [NSUserDefaults getCategoryModel:model.categoryId];
    [_icon setImage:[UIImage imageNamed:cmodel.icon_l]];
    [_nameLab setText:cmodel.name];
}

@end
