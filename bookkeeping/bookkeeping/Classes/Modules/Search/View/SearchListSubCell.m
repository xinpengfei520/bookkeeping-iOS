//
//  SearchListSubCell.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/12.
//  Copyright © 2022 kk. All rights reserved.
//

#import "SearchListSubCell.h"

@interface SearchListSubCell()

@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *nameLab;
@property (weak, nonatomic) IBOutlet UILabel *detailLab;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *iconConstraintL;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detailConstraintR;

@end

@implementation SearchListSubCell

- (void)initUI {
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    [self.nameLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.nameLab setTextColor:kColor_Text_Black];
    [self.detailLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.detailLab setTextColor:kColor_Text_Black];
    [self.iconConstraintL setConstant:countcoordinatesX(15)];
    [self.detailConstraintR setConstant:countcoordinatesX(15)];
}


#pragma mark - 点击
// 删除
- (IBAction)actionClick:(UIButton *)sender {
    [self routerEventWithName:HOME_CELL_REMOVE data:self];
}


#pragma mark - set
- (void)setModel:(BookDetailModel *)model {
    _model = model;
    BKCModel *cmodel = [NSUserDefaults getCategoryModel:model.categoryId];
    // 显示类别图表
    [_icon setImage:[UIImage imageNamed:cmodel.icon_l]];
    // 显示备注
    [_nameLab setText:model.mark];
    // 显示记账信息
    NSString *priceStr = [model getPriceStr];
    [_detailLab setText:cmodel.is_income == 0 ? [@"-" stringByAppendingString: priceStr] : priceStr];
}

@end
