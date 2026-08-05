/**
 * 图表页面：点击折线图的弹框 cell
 * @author 郑业强 2019-01-07
 * 2026-08-04 XIB → 代码布局（Batch 6）
 */

#import "BCHUDContentCell.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface BCHUDContentCell()

@property (nonatomic, strong) UIImageView *icon;
@property (nonatomic, strong) UILabel *nameLab;
@property (nonatomic, strong) UILabel *priceLab;
@property (nonatomic, strong) UILabel *detailLab;

@end

#pragma mark - 实现
@implementation BCHUDContentCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

// 原 XIB：[icon(10)][日期][ 16 ]类别 …… 金额(靠右)]，全部纵向占满
- (void)buildSubviews {
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    _icon = [[UIImageView alloc] init];
    _icon.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:_icon];

    _nameLab = [[UILabel alloc] init];
    [self.contentView addSubview:_nameLab];

    _detailLab = [[UILabel alloc] init];
    [self.contentView addSubview:_detailLab];

    _priceLab = [[UILabel alloc] init];
    [self.contentView addSubview:_priceLab];

    [_icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(self.contentView);
        make.width.equalTo(@10);
    }];
    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_icon.mas_right).offset(10);
        make.top.bottom.equalTo(self.contentView);
    }];
    [_detailLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_nameLab.mas_right).offset(countcoordinatesX(16));
        make.top.bottom.equalTo(self.contentView);
    }];
    [_priceLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView);
        make.top.bottom.equalTo(self.contentView);
    }];
}

- (void)initUI {
    // tooltip 深底浅字（kColor_Chart_* 两态皆为深底浅灰），保持与 BCHUDContent 一致
    [self setBackgroundColor:kColor_Chart_Header];
    [self.contentView setBackgroundColor:kColor_Chart_Header];
    [self.nameLab setFont:[UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(8)]];
    [self.detailLab setFont:[UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(8)]];
    [self.priceLab setFont:[UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(8)]];
    [self.nameLab setTextColor:kColor_Chart_Text];
    [self.detailLab setTextColor:kColor_Chart_Text];
    [self.priceLab setTextColor:kColor_Chart_Text];
}

#pragma mark - set
- (void)setModel:(BookDetailModel *)model {
    _model = model;
    BKCModel *cmodel = [NSUserDefaults getCategoryModel:model.categoryId];
    [_icon setImage:[UIImage imageNamed:cmodel.icon_l]];
    [_nameLab setText:[NSString stringWithFormat:@"%ld/%02ld/%02ld", model.year, model.month, model.day]];
    [_detailLab setText:cmodel.name];
    // 外币记录带小号原始金额角标（tooltip 金额本身 8pt，角标压到 6pt）；
    // 人民币记录原样显示，主体文字颜色仍走 label 的 Chart_Text
    [_priceLab setAttributedText:
        [model listPriceAttributedText:[model getPriceStr]
                             badgeFont:[UIFont systemFontOfSize:AdjustFont(6) weight:UIFontWeightLight]]];
}

@end
