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
    [self setBackgroundColor:kColor_Text_Black];
    [self.contentView setBackgroundColor:kColor_Text_Black];
    [self.nameLab setFont:[UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(8)]];
    [self.detailLab setFont:[UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(8)]];
    [self.priceLab setFont:[UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(8)]];
    [self.detailConstraintL setConstant:countcoordinatesX(30)];
}

#pragma mark - set
- (void)setModel:(BookDetailModel *)model {
    _model = model;
    BKCModel *cmodel = [NSUserDefaults getCategoryModel:model.categoryId];
    [_icon setImage:[UIImage imageNamed:cmodel.icon_l]];
    [_nameLab setText:[NSString stringWithFormat:@"%ld/%02ld/%02ld", model.year, model.month, model.day]];
    [_detailLab setText:cmodel.name];
    [_priceLab setText:[NSString stringWithFormat:@"%0.2f", model.price]];
}

@end
