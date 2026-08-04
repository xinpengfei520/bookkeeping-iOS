/**
 * 分享
 * @author 郑业强 2018-12-20 创建文件
 * 2026-08-04 XIB → 代码布局（Batch 7）
 */

#import "ShareOrder.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface ShareOrder()

@property (nonatomic, strong) UILabel *nameLab;
@property (nonatomic, strong) UILabel *cateLab;
@property (nonatomic, strong) UILabel *cateDescLab;
@property (nonatomic, strong) UILabel *moneyLab;
@property (nonatomic, strong) UIImageView *qrIcon;
@property (nonatomic, strong) UIImageView *sharkImg;
@property (nonatomic, strong) UIImageView *icon;

@end


#pragma mark - 实现
@implementation ShareOrder

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

// 原 XIB（240×371 模板）：左上日期/类别，右上二维码 + 鲨鱼 logo，
// 底部大图（share_expend2，481:448）撑满宽度，收支/金额压在大图上沿
- (void)buildSubviews {
    self.backgroundColor = UIColor.whiteColor;      // 分享出去的图固定白底

    _nameLab = [[UILabel alloc] init];
    _nameLab.text = @"2018年12月20日";
    [self addSubview:_nameLab];

    _cateLab = [[UILabel alloc] init];
    [self addSubview:_cateLab];

    _qrIcon = [[UIImageView alloc] init];
    [self addSubview:_qrIcon];

    _sharkImg = [[UIImageView alloc] init];
    _sharkImg.contentMode = UIViewContentModeScaleAspectFit;
    _sharkImg.image = [UIImage imageNamed:@"detail_share_shark"];
    [self addSubview:_sharkImg];

    _icon = [[UIImageView alloc] init];
    _icon.contentMode = UIViewContentModeScaleAspectFit;
    _icon.image = [UIImage imageNamed:@"share_expend2"];
    [self addSubview:_icon];

    _cateDescLab = [[UILabel alloc] init];
    [self addSubview:_cateDescLab];

    _moneyLab = [[UILabel alloc] init];
    [self addSubview:_moneyLab];

    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self).offset(10);
        make.height.equalTo(@15);
    }];
    [_cateLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_nameLab);
        make.top.equalTo(self->_nameLab.mas_bottom).offset(15);
        make.height.equalTo(@30);
    }];
    [_qrIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-10);
        make.top.equalTo(self->_nameLab);
        make.width.height.equalTo(@60);
    }];
    [_sharkImg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self->_qrIcon);
        make.top.equalTo(self->_qrIcon.mas_bottom).offset(5);
        make.width.equalTo(self->_qrIcon.mas_width).offset(-10);
        make.height.equalTo(self->_sharkImg.mas_width).multipliedBy(11.0 / 36.0);
    }];
    [_icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.height.equalTo(self->_icon.mas_width).multipliedBy(448.0 / 481.0);
    }];
    [_cateDescLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(10);
        make.bottom.equalTo(self->_icon.mas_top).offset(-15);
        make.height.equalTo(@20);
    }];
    [_moneyLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_cateDescLab.mas_right).offset(10);
        make.bottom.equalTo(self->_cateDescLab);
    }];
}

- (void)initUI {
    // 分享样图模板的示例文案
    [self.cateLab setText:KKLocalized(@"兼职")];
    [self.cateDescLab setText:KKLocalized(@"收入")];

    [self.nameLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.nameLab setTextColor:kColor_Text_Black];
    [self.cateLab setFont:[UIFont systemFontOfSize:AdjustFont(20) weight:UIFontWeightLight]];
    [self.cateLab setTextColor:kColor_Text_Black];
    [self.cateDescLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.cateDescLab setTextColor:kColor_Text_Black];
    [self.qrIcon setBackgroundColor:kColor_Red_Color];
    [self.moneyLab setAttributedText:[NSAttributedString createMath:@"99.00" integer:[UIFont systemFontOfSize:AdjustFont(22) weight:UIFontWeightLight] decimal:[UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight] color:kColor_Red_Color]];
}

@end
