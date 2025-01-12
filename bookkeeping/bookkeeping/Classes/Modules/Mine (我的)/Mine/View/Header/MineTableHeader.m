/**
 * 我的头视图
 * @author 郑业强 2018-12-16 创建文件
 */

#import "MineTableHeader.h"
#import <Masonry/Masonry.h>

@interface MineTableHeader()

@property (nonatomic, strong) UIImageView *icon;     // 头像
@property (nonatomic, strong) UIView *userInfoContainer; // 用户信息容器
@property (nonatomic, strong) UILabel *nameLab;      // 姓名
@property (nonatomic, strong) UILabel *joinTimeLab;  // 加入时间
@property (nonatomic, strong) UIImageView *arrowIcon; // 箭头图标
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
    
    // 头像
    _icon = [[UIImageView alloc] init];
    _icon.image = [UIImage imageNamed:@"default_header"];
    _icon.layer.cornerRadius = countcoordinatesX(30);
    _icon.layer.masksToBounds = YES;
    _icon.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:_icon];
    
    // 用户信息容器
    _userInfoContainer = [[UIView alloc] init];
    _userInfoContainer.backgroundColor = [UIColor clearColor];
    [self addSubview:_userInfoContainer];
    
    // 用户名
    _nameLab = [[UILabel alloc] init];
    _nameLab.text = @"未登录";
    _nameLab.font = [UIFont systemFontOfSize:AdjustFont(16) weight:UIFontWeightMedium];
    _nameLab.textColor = kColor_Text_White;
    [_userInfoContainer addSubview:_nameLab];
    
    // 加入时间
    _joinTimeLab = [[UILabel alloc] init];
    _joinTimeLab.text = @"期待你加入";
    _joinTimeLab.font = [UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight];
    _joinTimeLab.textColor = [UIColor colorWithWhite:1 alpha:0.7];
    [_userInfoContainer addSubview:_joinTimeLab];
    
    // 箭头图标
    _arrowIcon = [[UIImageView alloc] init];
    _arrowIcon.image = [UIImage imageNamed:@"icon_nav_to_next"]; // 请确保有这个图片资源
    _arrowIcon.contentMode = UIViewContentModeScaleAspectFit;
    _arrowIcon.tintColor = kColor_Text_White;
    [self addSubview:_arrowIcon];
    
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
    // 头像约束
    [_icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(countcoordinatesX(20));
        make.top.equalTo(self).offset(StatusBarHeight + countcoordinatesX(60));
        make.size.mas_equalTo(CGSizeMake(countcoordinatesX(60), countcoordinatesX(60)));
    }];
    
    // 用户信息容器约束
    [_userInfoContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_icon.mas_right).offset(countcoordinatesX(15));
        make.centerY.equalTo(_icon);
        make.right.equalTo(_arrowIcon.mas_left).offset(-countcoordinatesX(10));
    }];
    
    // 用户名约束
    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.equalTo(_userInfoContainer);
    }];
    
    // 加入时间约束
    [_joinTimeLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(_userInfoContainer);
        make.top.equalTo(_nameLab.mas_bottom).offset(5);
    }];
    
    // 箭头图标约束
    [_arrowIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-countcoordinatesX(20));
        make.centerY.equalTo(_icon);
        make.size.mas_equalTo(CGSizeMake(countcoordinatesX(16), countcoordinatesX(16)));
    }];
    
    [_dayView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self);
        make.top.equalTo(_icon.mas_bottom).offset(countcoordinatesX(20));
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
    // 移除原有的点击事件
    // 添加整个视图的点击事件
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headerTapped)];
    [self addGestureRecognizer:tap];
    
    // ... 其他点击事件保持不变 ...
}

- (void)headerTapped {
    [self routerEventWithName:MINE_HEADER_ICON_CLICK data:nil];
}

#pragma mark - set
- (void)setModel:(UserModel *)model {
    _model = model;
    // 未登录状态
    if (!model) {
        [_icon setImage:[UIImage imageNamed:@"default_header"]];
        [_nameLab setText:@"未登录"];
        [_joinTimeLab setText:@"期待你加入"];
        [_dayLab setText:@"0"];
        [_numberLab setText:@"0"];
        return;
    }
    
    // 已登录状态
    if (model.userAvatar) {
        [_icon sd_setImageWithURL:[NSURL URLWithString:model.userAvatar]];
    } else {
        [_icon setImage:[UIImage imageNamed:@"default_header"]];
    }
    [_nameLab setText:model.nickname];
    
    // 格式化注册时间
    if (model.registerTime) {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[model.registerTime doubleValue]];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy年MM月"];
        NSString *dateString = [formatter stringFromDate:date];
        [_joinTimeLab setText:[NSString stringWithFormat:@"%@加入", dateString]];
    }
    
    [_dayLab setText:model.bookDays];
    [_numberLab setText:model.bookCounts];
}

@end
