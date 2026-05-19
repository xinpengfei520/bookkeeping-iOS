//
//  SearchListHeader.m (code-only — converted from SearchListHeader.xib)
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/12.
//  Copyright © 2022 kk. All rights reserved.
//

#import "SearchListHeader.h"
#import <Masonry/Masonry.h>

@interface SearchListHeader()

@property (nonatomic, strong) UILabel *nameLab;
@property (nonatomic, strong) UILabel *detailLab;
@property (nonatomic, strong) UIView *line;

@end

@implementation SearchListHeader

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
        [self initUI];
    }
    return self;
}

- (void)buildSubviews {
    // XIB 把背景烤成 sRGB 白，dark mode 会保持白；走 systemBackgroundColor 让系统跟随
    self.backgroundColor = [UIColor systemBackgroundColor];

    _nameLab = [[UILabel alloc] init];
    [self addSubview:_nameLab];

    _detailLab = [[UILabel alloc] init];
    _detailLab.textAlignment = NSTextAlignmentRight;
    [self addSubview:_detailLab];

    _line = [[UIView alloc] init];
    [self addSubview:_line];

    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(countcoordinatesX(15));
        make.top.equalTo(self);
        make.bottom.equalTo(self->_line.mas_top);
    }];
    [_detailLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-countcoordinatesX(15));
        make.top.equalTo(self);
        make.bottom.equalTo(self->_line.mas_top);
    }];
    [_line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.height.equalTo(@0.5);
    }];
}

- (void)initUI {
    [self.nameLab setFont:[UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(10)]];
    [self.nameLab setTextColor:kColor_Text_Gary];
    [self.detailLab setFont:[UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(10)]];
    [self.detailLab setTextColor:kColor_Text_Gary];
    [self.line setBackgroundColor:kColor_Line_Color];
}

- (void)setModel:(BookMonthModel *)model {
    _model = model;
    [_nameLab setText:[model getDateDescribeWithYear]];
    [_detailLab setText:[model getMoneyDescribe]];
}

@end
