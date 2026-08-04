/**
 * 分享徽章
 * @author 郑业强 2018-12-21 创建文件
 * 2026-08-04 XIB → 代码布局（Batch 7）
 */

#import "ShareBadge.h"
#import <Masonry/Masonry.h>


#pragma mark - 声明
@interface ShareBadge()

@property (nonatomic, strong) UIImageView *bgImg;
@property (nonatomic, strong) UIImageView *icon;
@property (nonatomic, strong) UILabel *nameLab;
@property (nonatomic, strong) UIImageView *badge;
@property (nonatomic, strong) UILabel *titleLab;
@property (nonatomic, strong) UILabel *detailLab;
@property (nonatomic, strong) UILabel *tipLab1;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIImageView *siginIcon;

@end


#pragma mark - 实现
@implementation ShareBadge

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

// 原 XIB（266×427 模板）：背景大图铺上半区（以徽章为中心），
// 头像 → 昵称 → 徽章图(宽 3/5, 1:1)，底部：标题/励志语 + 白色底条(打卡 icon + 标语)
- (void)buildSubviews {
    self.backgroundColor = UIColor.whiteColor;      // 分享出去的图固定白底

    _bgImg = [[UIImageView alloc] init];
    _bgImg.contentMode = UIViewContentModeScaleAspectFill;
    _bgImg.image = [UIImage imageNamed:@"share_badge_bg"];
    [self addSubview:_bgImg];

    _icon = [[UIImageView alloc] init];
    _icon.contentMode = UIViewContentModeScaleAspectFit;
    _icon.image = [UIImage imageNamed:@"default_header"];
    [self addSubview:_icon];

    _nameLab = [[UILabel alloc] init];
    _nameLab.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_nameLab];

    _badge = [[UIImageView alloc] init];
    _badge.contentMode = UIViewContentModeScaleAspectFit;
    _badge.image = [UIImage imageNamed:@"cc_catering_bottle"];
    [self addSubview:_badge];

    _titleLab = [[UILabel alloc] init];
    _titleLab.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_titleLab];

    _detailLab = [[UILabel alloc] init];
    _detailLab.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_detailLab];

    _bottomView = [[UIView alloc] init];
    _bottomView.backgroundColor = UIColor.whiteColor;
    [self addSubview:_bottomView];

    _siginIcon = [[UIImageView alloc] init];
    _siginIcon.contentMode = UIViewContentModeScaleAspectFit;
    _siginIcon.image = [UIImage imageNamed:@"sigin_icon"];
    [_bottomView addSubview:_siginIcon];

    _tipLab1 = [[UILabel alloc] init];
    [_bottomView addSubview:_tipLab1];

    [_bgImg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self);
        make.centerX.equalTo(self->_badge);
        make.centerY.equalTo(self->_badge);
    }];
    [_icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(20);
        make.centerX.equalTo(self);
        make.width.height.equalTo(@50);
    }];
    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self->_icon.mas_bottom).offset(10);
        make.left.right.equalTo(self);
        make.height.equalTo(@20);
    }];
    [_badge mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self->_nameLab.mas_bottom).offset(20);
        make.centerX.equalTo(self);
        make.width.equalTo(self.mas_width).multipliedBy(0.6);
        make.height.equalTo(self->_badge.mas_width);
    }];
    [_bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.height.equalTo(@(countcoordinatesX(70)));
    }];
    [_detailLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self);
        make.bottom.equalTo(self->_bottomView.mas_top).offset(-15);
    }];
    [_titleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self);
        make.bottom.equalTo(self->_detailLab.mas_top).offset(-10);
    }];
    [_siginIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_bottomView).offset(20);
        make.centerY.equalTo(self->_bottomView);
        make.height.equalTo(self->_bottomView.mas_height).offset(-30);
        make.width.equalTo(self->_siginIcon.mas_height);
    }];
    [_tipLab1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_siginIcon.mas_right).offset(8);
        make.bottom.equalTo(self->_siginIcon).offset(-3);
    }];
}

- (void)initUI {
    [self.layer setMasksToBounds:YES];
    // 徽章模板上的标题 / 励志语 / 副标题
    [self.titleLab setText:KKLocalized(@"连续3天打卡徽章")];
    [self.detailLab setText:KKLocalized(@"成功是持续积累而成")];
    [self.tipLab1 setText:KKLocalized(@"爱记账，爱生活")];

    [self.nameLab setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.nameLab setTextColor:kColor_Text_Black];
    [self.titleLab setFont:[UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight]];
    [self.titleLab setTextColor:kColor_Text_Black];
    [self.detailLab setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.detailLab setTextColor:kColor_Text_Black];
    [self.tipLab1 setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.tipLab1 setTextColor:kColor_Text_Black];
}

@end
