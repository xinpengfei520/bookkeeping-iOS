/**
 * ChartTableCell (code-only — converted from ChartTableCell.xib)
 * @author 郑业强 2018-12-18 创建文件
 */

#import "ChartTableCell.h"
#import <Masonry/Masonry.h>

#define ICON_W countcoordinatesX(25)
#define LINE_L countcoordinatesX(10)

#pragma mark - 声明
@interface ChartTableCell()

@property (nonatomic, strong) UIImageView *icon;
@property (nonatomic, strong) UILabel *nameLab;
@property (nonatomic, strong) UILabel *detailLab;
@property (nonatomic, strong) UILabel *percentLab;
@property (nonatomic, strong) UIImageView *line;

@end


#pragma mark - 实现
@implementation ChartTableCell

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

    _percentLab = [[UILabel alloc] init];
    [self.contentView addSubview:_percentLab];

    _line = [[UIImageView alloc] init];
    [self.contentView addSubview:_line];

    [_icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(OUT_PADDING);
        make.top.bottom.equalTo(self.contentView);
        make.width.equalTo(@(ICON_W));
    }];
    // nameLab + percentLab + detailLab 三个 label centerY 对齐，位于 line 上方
    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_icon.mas_right).offset(LINE_L);
        make.centerY.equalTo(self.contentView).offset(-countcoordinatesX(8));
    }];
    [_percentLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_nameLab.mas_right).offset(8);
        make.centerY.equalTo(self->_nameLab);
    }];
    [_detailLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-OUT_PADDING);
        make.centerY.equalTo(self->_nameLab);
    }];
    // line 横条：高 5pt 圆角胶囊；宽度（lineConstraintW）在 setModel 里按 price 比例改
    [_line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_nameLab);
        make.top.equalTo(self->_nameLab.mas_bottom).offset(8);
        make.width.equalTo(@0);  // 初始 0，setModel 时按比例 update
        make.height.equalTo(@(countcoordinatesX(5)));
    }];
}

- (void)initUI {
    [self.nameLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.nameLab setTextColor:kColor_Text_Black];
    [self.percentLab setFont:[UIFont systemFontOfSize:AdjustFont(8) weight:UIFontWeightLight]];
    [self.percentLab setTextColor:kColor_Text_Black];
    [self.detailLab setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.detailLab setTextColor:kColor_Text_Black];
    [self.line setImage:[UIColor createImageWithColor:kColor_Main_Color]];
    [self.line.layer setCornerRadius:countcoordinatesX(5) / 2];
    [self.line.layer setMasksToBounds:true];
}


#pragma mark - set
- (void)setModel:(BookDetailModel *)model {
    _model = model;
    BKCModel *cmodel = [NSUserDefaults getCategoryModel:model.categoryId];
    [_icon setImage:[UIImage imageNamed:cmodel.icon_l]];
    [_nameLab setText:_isBookDetail?model.mark:cmodel.name];
    [_percentLab setText:[NSString stringWithFormat:@"%.1f%%",model.price*100/_sumPrice]];
    [_detailLab setText:[model getPriceStr]];

    CGFloat width = SCREEN_WIDTH - OUT_PADDING * 2 - ICON_W - LINE_L;
    width = width / _maxPrice * model.price;
    [self.line mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(width));
    }];
}


@end
