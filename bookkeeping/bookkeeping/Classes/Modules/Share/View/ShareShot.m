/**
 * 截图
 * @author 郑业强 2018-12-20 创建文件
 * 2026-08-04 XIB → 代码布局（Batch 7）。原 XIB 里"记账总天数/记账总笔数"两个
 * label 没绑 outlet、无法 localize —— 迁代码后一并走 KKLocalized。
 */

#import "ShareShot.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface ShareShot()

@property (nonatomic, strong) UILabel *titleLab;
@property (nonatomic, strong) UIImageView *icon;
@property (nonatomic, strong) UILabel *nameLab;
@property (nonatomic, strong) UILabel *tipLab1;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIImageView *shareIcon;
@property (nonatomic, strong) UIImageView *honorImg;
@property (nonatomic, strong) UILabel *dayLabel;
@property (nonatomic, strong) UILabel *numLabel;

@end


#pragma mark - 实现
@implementation ShareShot

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

// 原 XIB（262×370 模板，供离屏截图）：
//   标题 → 头像(50) → 昵称 → [弹性空隙] → 天数/笔数两列 → [等高空隙] → 徽章图 → 橙色底条
- (void)buildSubviews {
    self.backgroundColor = UIColor.whiteColor;      // 分享出去的图固定白底，不跟随 dark mode

    _titleLab = [[UILabel alloc] init];
    _titleLab.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_titleLab];

    _icon = [[UIImageView alloc] init];
    _icon.contentMode = UIViewContentModeScaleAspectFit;
    _icon.image = [UIImage imageNamed:@"default_header"];
    [self addSubview:_icon];

    _nameLab = [[UILabel alloc] init];
    _nameLab.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_nameLab];

    UIView *spacer1 = [[UIView alloc] init];
    UIView *spacer2 = [[UIView alloc] init];
    [self addSubview:spacer1];
    [self addSubview:spacer2];

    UIView *stats = [[UIView alloc] init];
    [self addSubview:stats];

    _dayLabel = [[UILabel alloc] init];
    _dayLabel.tag = 10;
    _dayLabel.textAlignment = NSTextAlignmentCenter;
    [stats addSubview:_dayLabel];

    UILabel *dayTip = [[UILabel alloc] init];
    dayTip.tag = 11;
    dayTip.text = KKLocalized(@"记账总天数");
    dayTip.textAlignment = NSTextAlignmentCenter;
    [stats addSubview:dayTip];

    _numLabel = [[UILabel alloc] init];
    _numLabel.tag = 10;
    _numLabel.textAlignment = NSTextAlignmentCenter;
    [stats addSubview:_numLabel];

    UILabel *numTip = [[UILabel alloc] init];
    numTip.tag = 11;
    numTip.text = KKLocalized(@"记账总笔数");
    numTip.textAlignment = NSTextAlignmentCenter;
    [stats addSubview:numTip];

    _honorImg = [[UIImageView alloc] init];
    _honorImg.contentMode = UIViewContentModeScaleAspectFit;
    _honorImg.image = [UIImage imageNamed:@"sigin_honor"];
    [self addSubview:_honorImg];

    _bottomView = [[UIView alloc] init];
    [self addSubview:_bottomView];

    _shareIcon = [[UIImageView alloc] init];
    _shareIcon.contentMode = UIViewContentModeScaleAspectFit;
    _shareIcon.image = [UIImage imageNamed:@"share_icon"];
    [_bottomView addSubview:_shareIcon];

    _tipLab1 = [[UILabel alloc] init];
    [_bottomView addSubview:_tipLab1];

    // ---- 约束 ----
    [_titleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(20);
        make.left.right.equalTo(self);
    }];
    [_icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self->_titleLab.mas_bottom).offset(10);
        make.centerX.equalTo(self);
        make.width.height.equalTo(@50);
    }];
    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self->_icon.mas_bottom).offset(5);
        make.left.right.equalTo(self);
        make.height.equalTo(@20);
    }];
    [spacer1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self->_nameLab.mas_bottom);
        make.left.right.equalTo(self);
    }];
    [stats mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(spacer1.mas_bottom);
        make.left.right.equalTo(self);
    }];
    [spacer2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(stats.mas_bottom);
        make.left.right.equalTo(self);
        make.height.equalTo(spacer1);
    }];
    // 两列：天数列在 ~27% 处，笔数列在 ~69% 处（与原 XIB 的像素位置一致）
    [_dayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(stats);
        make.centerX.equalTo(stats.mas_centerX).multipliedBy(0.53);
    }];
    [dayTip mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self->_dayLabel.mas_bottom).offset(5);
        make.centerX.equalTo(self->_dayLabel);
        make.bottom.equalTo(stats);
    }];
    [_numLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(stats);
        make.centerX.equalTo(stats.mas_centerX).multipliedBy(1.38);
    }];
    [numTip mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self->_numLabel.mas_bottom).offset(5);
        make.centerX.equalTo(self->_numLabel);
    }];
    [_honorImg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(spacer2.mas_bottom);
        make.centerX.equalTo(self);
        make.width.equalTo(self.mas_width).multipliedBy(0.5);
        make.height.equalTo(self->_honorImg.mas_width).multipliedBy(133.0 / 223.0);
    }];
    [_bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self->_honorImg.mas_bottom).offset(-5);
        make.left.right.bottom.equalTo(self);
        make.height.equalTo(@(countcoordinatesX(70)));
    }];
    [_shareIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_bottomView).offset(20);
        make.centerY.equalTo(self->_bottomView);
        make.height.equalTo(self->_bottomView.mas_height).offset(-countcoordinatesX(30));
        make.width.equalTo(self->_shareIcon.mas_height);
    }];
    [_tipLab1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_shareIcon.mas_right).offset(8);
        make.bottom.equalTo(self->_shareIcon).offset(-3);
    }];
}

- (void)initUI {
    [self.titleLab setText:KKLocalized(@"记账成就")];
    [self.tipLab1 setText:KKLocalized(@"爱记账，爱生活")];

    [self.titleLab setFont:[UIFont systemFontOfSize:AdjustFont(14)]];
    [self.titleLab setTextColor:kColor_Text_Black];

    [self.icon.layer setCornerRadius:25];   // 50pt 头像取半
    [self.icon.layer setBorderWidth:1.f / [UIScreen mainScreen].scale];
    [self.icon.layer setBorderColor:kColor_BG.CGColor];
    [self.icon.layer setMasksToBounds:true];

    [self.nameLab setFont:[UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight]];
    [self.nameLab setTextColor:kColor_Text_Black];
    [self.tipLab1 setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.tipLab1 setTextColor:kColor_Text_White];
    // 原 XIB 底条的橙色（displayP3 1, 0.57, 0.30）
    [self.bottomView setBackgroundColor:RGBA(255, 145, 77, 1)];
    [self createLabFont:self];
}


- (void)createLabFont:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *lab = (UILabel *)subview;
            if (lab.tag == 10) {
                lab.font = [UIFont systemFontOfSize:AdjustFont(14)];
                lab.textColor = kColor_Text_Black;
            } else if (lab.tag == 11) {
                lab.font = [UIFont systemFontOfSize:AdjustFont(8) weight:UIFontWeightThin];
                lab.textColor = kColor_Text_Black;
            }
        } else {
            [self createLabFont:subview];
        }
    }
}

- (void)setModel:(UserModel *)model {
    _model = model;
    [self.nameLab setText:model.nickname];
    [self.dayLabel setText:model.bookDays];
    [self.numLabel setText:model.bookCounts];
    if (model.userAvatar) {
        [_icon sd_setImageWithURL:[NSURL URLWithString:model.userAvatar]];
    }else {
        [_icon setImage:[UIImage imageNamed:@"default_header"]];
    }
}

@end
