//
//  SearchListSubCell.m (code-only — converted from SearchListSubCell.xib)
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/12.
//  Copyright © 2022 kk. All rights reserved.
//

#import "SearchListSubCell.h"
#import <Masonry/Masonry.h>

@interface SearchListSubCell()

@property (nonatomic, strong) UIImageView *icon;
@property (nonatomic, strong) UILabel *nameLab;
@property (nonatomic, strong) UILabel *detailLab;

@end

@implementation SearchListSubCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

- (void)buildSubviews {
    _icon = [[UIImageView alloc] init];
    _icon.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:_icon];

    _nameLab = [[UILabel alloc] init];
    [self.contentView addSubview:_nameLab];

    _detailLab = [[UILabel alloc] init];
    [self.contentView addSubview:_detailLab];

    [_icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(countcoordinatesX(15));
        make.top.bottom.equalTo(self.contentView);
        make.width.equalTo(@25);
    }];
    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_icon.mas_right).offset(10);
        make.top.bottom.equalTo(self.contentView);
    }];
    [_detailLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-countcoordinatesX(15));
        make.top.bottom.equalTo(self.contentView);
    }];
}

- (void)initUI {
    [self.nameLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.nameLab setTextColor:kColor_Text_Black];
    [self.detailLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.detailLab setTextColor:kColor_Text_Black];
}


#pragma mark - set
- (void)setModel:(BookDetailModel *)model {
    _model = model;
    BKCModel *cmodel = [NSUserDefaults getCategoryModel:model.categoryId];
    // 显示类别图表
    [_icon setImage:[UIImage imageNamed:cmodel.icon_l]];
    // 显示备注
    [_nameLab setText:model.mark];
    // 显示记账信息(人民币；外币记录在前面加一个小号灰字的原始金额角标)
    NSString *priceStr = [model getPriceStr];
    NSString *text = cmodel.is_income == 0 ? [@"-" stringByAppendingString: priceStr] : priceStr;
    [_detailLab setAttributedText:[model listPriceAttributedText:text]];
}

@end
