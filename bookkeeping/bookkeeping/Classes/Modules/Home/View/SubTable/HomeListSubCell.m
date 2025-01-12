/**
 * 列表Cell
 * @author 郑业强 2018-12-18 创建文件
 */

#import "HomeListSubCell.h"
#import <Masonry/Masonry.h>

@interface HomeListSubCell()

@property (nonatomic, strong) UIImageView *icon;
@property (nonatomic, strong) UILabel *nameLab;
@property (nonatomic, strong) UILabel *detailLab;

@end

@implementation HomeListSubCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    // 图标
    _icon = [[UIImageView alloc] init];
    _icon.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:_icon];
    
    // 名称标签
    _nameLab = [[UILabel alloc] init];
    _nameLab.font = [UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight];
    _nameLab.textColor = kColor_Text_Black;
    [self.contentView addSubview:_nameLab];
    
    // 详情标签
    _detailLab = [[UILabel alloc] init];
    _detailLab.font = [UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight];
    _detailLab.textColor = kColor_Text_Black;
    [self.contentView addSubview:_detailLab];
    
    // 设置约束
    [_icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(countcoordinatesX(15));
        make.centerY.equalTo(self.contentView);
        make.width.height.equalTo(@25);
    }];
    
    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_icon.mas_right).offset(10);
        make.centerY.equalTo(self.contentView);
    }];
    
    [_detailLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-countcoordinatesX(15));
        make.centerY.equalTo(self.contentView);
    }];
    
    // 设置滑动删除按钮
    @weakify(self)
    MGSwipeButton *btn = [MGSwipeButton buttonWithTitle:@"删除" backgroundColor:kColor_Red_Color];
    [btn.titleLabel setFont:[UIFont systemFontOfSize:AdjustFont(14)]];
    [btn setButtonWidth:countcoordinatesX(80)];
    [btn setCallback:^BOOL(MGSwipeTableCell *cell) {
        @strongify(self)
        [self routerEventWithName:HOME_CELL_REMOVE data:self];
        return NO;
    }];
    [self setRightButtons:@[btn]];
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
