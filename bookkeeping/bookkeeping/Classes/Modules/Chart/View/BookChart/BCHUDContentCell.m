/**
 * 图表页面：点击折线图的弹框 cell
 * @author 郑业强 2019-01-07
 */

#import "BCHUDContentCell.h"

#pragma mark - 声明
@interface BCHUDContentCell()

@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *nameLab;
@property (weak, nonatomic) IBOutlet UILabel *priceLab;
@property (weak, nonatomic) IBOutlet UILabel *detailLab;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detailConstraintL;

@end

#pragma mark - 实现
@implementation BCHUDContentCell

- (void)initUI {
    // 配合 BCHUDContent 的深色 tooltip 底：cell 也用 Chart_Header；XIB 烤死白字在 dark mode
    // 接管不到，统一在这里显式设为 Chart_Text（两态都是浅灰），确保深底浅字可读
    [self setBackgroundColor:kColor_Chart_Header];
    [self.contentView setBackgroundColor:kColor_Chart_Header];
    [self.nameLab setFont:[UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(8)]];
    [self.detailLab setFont:[UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(8)]];
    [self.priceLab setFont:[UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(8)]];
    [self.nameLab setTextColor:kColor_Chart_Text];
    [self.detailLab setTextColor:kColor_Chart_Text];
    [self.priceLab setTextColor:kColor_Chart_Text];
    // detailLab 距离 _nameLab 的距离
    [self.detailConstraintL setConstant:countcoordinatesX(16)];
}

#pragma mark - set
- (void)setModel:(BookDetailModel *)model {
    _model = model;
    BKCModel *cmodel = [NSUserDefaults getCategoryModel:model.categoryId];
    [_icon setImage:[UIImage imageNamed:cmodel.icon_l]];
    [_nameLab setText:[NSString stringWithFormat:@"%ld/%02ld/%02ld", model.year, model.month, model.day]];
    [_detailLab setText:cmodel.name];
    [_priceLab setText:[model getPriceStr]];
}

@end
