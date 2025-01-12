/**
 * 我的头视图
 * @author 郑业强 2018-12-16 创建文件
 */

#import "MineTableHeader.h"
#import <Masonry/Masonry.h>

@interface MineTableHeader()

@property (nonatomic, strong) UIImageView *icon;     // 头像
@property (nonatomic, strong) UILabel *nameLab;      // 姓名
@property (nonatomic, strong) UIView *infoView;      // 个人信息
@property (nonatomic, strong) UIView *dayView;
@property (nonatomic, strong) UIView *numberView;
@property (nonatomic, strong) UILabel *dayLab;
@property (nonatomic, strong) UILabel *numberLab;
@property (nonatomic, strong) UILabel *dayTitleLab;
@property (nonatomic, strong) UILabel *numberTitleLab;

@end

@implementation MineTableHeader

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self setBackgroundColor:kColor_Main_Color];
    
    // 个人信息视图
    _infoView = [[UIView alloc] init];
    _infoView.clipsToBounds = NO;
    _infoView.backgroundColor = [UIColor clearColor];
    [self addSubview:_infoView];
    
    // 头像
    _icon = [[UIImageView alloc] init];
    _icon.image = [UIImage imageNamed:@"default_header"];
    _icon.layer.cornerRadius = countcoordinatesX(35);
    _icon.layer.masksToBounds = YES;
    _icon.contentMode = UIViewContentModeScaleAspectFill;
    [_infoView addSubview:_icon];
    
    // 用户名
    _nameLab = [[UILabel alloc] init];
    _nameLab.text = @"未登录";
    _nameLab.font = [UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight];
    _nameLab.textColor = kColor_Text_White;
    _nameLab.textAlignment = NSTextAlignmentCenter;
    [_infoView addSubview:_nameLab];
    
    // 记账天数视图
    _dayView = [[UIView alloc] init];
    _dayView.backgroundColor = [UIColor clearColor];
    [self addSubview:_dayView];
    
    // 记账天数
    _dayLab = [[UILabel alloc] init];
    _dayLab.text = @"0";
    _dayLab.font = [UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight];
    _dayLab.textColor = kColor_Text_White;
    _dayLab.textAlignment = NSTextAlignmentCenter;
    [_dayView addSubview:_dayLab];
    
    // 记账天数标题
    _dayTitleLab = [[UILabel alloc] init];
    _dayTitleLab.text = @"记账总天数";
    _dayTitleLab.font = [UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight];
    _dayTitleLab.textColor = kColor_Text_White;
    _dayTitleLab.textAlignment = NSTextAlignmentCenter;
    [_dayView addSubview:_dayTitleLab];
    
    // 记账笔数视图
    _numberView = [[UIView alloc] init];
    _numberView.backgroundColor = [UIColor clearColor];
    [self addSubview:_numberView];
    
    // 记账笔数
    _numberLab = [[UILabel alloc] init];
    _numberLab.text = @"0";
    _numberLab.font = [UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight];
    _numberLab.textColor = kColor_Text_White;
    _numberLab.textAlignment = NSTextAlignmentCenter;
    [_numberView addSubview:_numberLab];
    
    // 记账笔数标题
    _numberTitleLab = [[UILabel alloc] init];
    _numberTitleLab.text = @"记账总笔数";
    _numberTitleLab.font = [UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight];
    _numberTitleLab.textColor = kColor_Text_White;
    _numberTitleLab.textAlignment = NSTextAlignmentCenter;
    [_numberView addSubview:_numberTitleLab];
    
    // 设置约束
    [self setupConstraints];
    
    // 添加点击事件
    [self setupActions];
}

- (void)setupConstraints {
    [_infoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self).offset(StatusBarHeight + countcoordinatesX(40));
        make.width.equalTo(@70);
    }];
    
    [_icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_infoView);
        make.centerX.equalTo(_infoView);
        make.size.mas_equalTo(CGSizeMake(countcoordinatesX(70), countcoordinatesX(70)));
    }];
    
    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_icon.mas_bottom).offset(5);
        make.centerX.equalTo(_infoView);
        make.bottom.equalTo(_infoView);
    }];
    
    [_dayView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self);
        make.top.equalTo(_infoView.mas_bottom).offset(countcoordinatesX(10));
        make.width.equalTo(self).multipliedBy(0.5);
        make.height.equalTo(@62);
    }];
    
    [_dayLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_dayView);
        make.top.equalTo(_dayView).offset(8);
    }];
    
    [_dayTitleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_dayView);
        make.bottom.equalTo(_dayView).offset(-8);
    }];
    
    [_numberView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self);
        make.top.equalTo(_dayView);
        make.width.height.equalTo(_dayView);
    }];
    
    [_numberLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_numberView);
        make.top.equalTo(_numberView).offset(8);
    }];
    
    [_numberTitleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_numberView);
        make.bottom.equalTo(_numberView).offset(-8);
    }];
}

- (void)setupActions {
    @weakify(self)
    // 头像点击
    [self.infoView addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
        @strongify(self)
        [self routerEventWithName:MINE_HEADER_ICON_CLICK data:nil];
    }];
    
    // 记账总天数点击
    [self.dayView addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
        @strongify(self)
        [self routerEventWithName:MINE_HEADER_DAY_CLICK data:nil];
    }];
    
    // 记账总笔数点击
    [self.numberView addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
        @strongify(self)
        [self routerEventWithName:MINE_HEADER_NUMBER_CLICK data:nil];
    }];
}

#pragma mark - set
- (void)setModel:(UserModel *)model {
    _model = model;
    // 未登录
    if (!model) {
        [_icon setImage:[UIImage imageNamed:@"default_header"]];
        [_nameLab setText:@"未登录"];
        [_dayLab setText:@"0"];
        [_numberLab setText:@"0"];
        return;
    }
    
    if (model.userAvatar) {
        [_icon sd_setImageWithURL:[NSURL URLWithString:model.userAvatar]];
    } else {
        [_icon setImage:[UIImage imageNamed:@"default_header"]];
    }
    [_nameLab setText:model.nickname];
    [_dayLab setText:model.bookDays];
    [_numberLab setText:model.bookCounts];
}

@end
