/**
 * 头视图（code-only — pilot conversion from HomeHeader.xib）
 * @author 郑业强 2018-12-16 创建文件
 */

#import "HomeHeader.h"
#import "UIButton+EnlargeTouchArea.h"
#import "BookMonthModel.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface HomeHeader()

@property (nonatomic, strong) UIView *monthView;       // 左上 year+month 区，整体可点击
@property (nonatomic, strong) UILabel *yearLab;
@property (nonatomic, strong) UILabel *monthLab;
@property (nonatomic, strong) UILabel *monthDescLab;   // "月" / "Mo." 后缀
@property (nonatomic, strong) UIImageView *monthArrow; // 小三角向下箭头
@property (nonatomic, strong) UIView *line;            // 中间垂直分隔线
@property (nonatomic, strong) UILabel *incomeDescLab;
@property (nonatomic, strong) UILabel *payDescLab;
@property (nonatomic, strong) UILabel *incomeLab;      // 数字（attributed）
@property (nonatomic, strong) UILabel *payLab;         // 数字（attributed）
@property (nonatomic, strong) UIButton *moneyShow;     // 金额脱敏切换

@end


#pragma mark - 实现
@implementation HomeHeader

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
        [self initUI];
    }
    return self;
}

- (void)buildSubviews {
    self.backgroundColor = kColor_Main_Color;

    _monthView = [[UIView alloc] init];
    [self addSubview:_monthView];

    _yearLab = [[UILabel alloc] init];
    [self addSubview:_yearLab];

    _monthLab = [[UILabel alloc] init];
    [self addSubview:_monthLab];

    _monthDescLab = [[UILabel alloc] init];
    [self addSubview:_monthDescLab];

    _monthArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"time_down"]];
    _monthArrow.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:_monthArrow];

    _line = [[UIView alloc] init];
    [self addSubview:_line];

    _incomeDescLab = [[UILabel alloc] init];
    [self addSubview:_incomeDescLab];

    _payDescLab = [[UILabel alloc] init];
    [self addSubview:_payDescLab];

    _incomeLab = [[UILabel alloc] init];
    _incomeLab.userInteractionEnabled = YES;
    [self addSubview:_incomeLab];

    _payLab = [[UILabel alloc] init];
    _payLab.userInteractionEnabled = YES;
    [self addSubview:_payLab];

    _moneyShow = [UIButton buttonWithType:UIButtonTypeCustom];
    [self addSubview:_moneyShow];

    // 约束（按 XIB 还原；保留 c2e2707 的 monthDescLab 最小尺寸防止语言切换布局回流）
    [_yearLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(countcoordinatesX(15));
        make.top.equalTo(self).offset(8);
        make.width.equalTo(@(countcoordinatesX(60)));
    }];
    [_monthLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_yearLab);
        make.top.equalTo(self->_yearLab.mas_bottom).offset(5);
    }];
    [_monthDescLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self->_monthLab.mas_bottom).offset(-2);
        make.left.equalTo(self->_monthLab.mas_right).offset(3);
        make.width.greaterThanOrEqualTo(@(countcoordinatesX(14)));
        make.height.greaterThanOrEqualTo(@(countcoordinatesX(12)));
    }];
    [_monthArrow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self->_monthDescLab);
        make.left.equalTo(self->_monthDescLab.mas_right).offset(3);
        make.width.height.equalTo(@10);
    }];
    [_line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(countcoordinatesX(100));
        make.centerY.equalTo(self->_monthArrow);
        make.width.equalTo(@1);
        make.height.equalTo(@30);
    }];
    [_incomeDescLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_line.mas_right).offset(32);
        make.centerY.equalTo(self->_yearLab);
    }];
    [_payDescLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_incomeDescLab.mas_right).offset(88);
        make.centerY.equalTo(self->_yearLab);
    }];
    [_incomeLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_incomeDescLab);
        make.centerY.equalTo(self->_line);
    }];
    [_payLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_payDescLab);
        make.centerY.equalTo(self->_line);
    }];
    [_monthView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.left.equalTo(self);
        make.right.equalTo(self->_line);
    }];
    [_moneyShow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-countcoordinatesX(20));
        make.centerY.equalTo(self).offset(-12);
    }];
}

- (void)initUI {
    [self.yearLab setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.yearLab setTextColor:kColor_Text_White];
    [self.monthLab setFont:[UIFont systemFontOfSize:AdjustFont(20) weight:UIFontWeightLight]];
    [self.monthLab setTextColor:kColor_Text_White];

    [self.payDescLab setText:KKLocalized(@"支出")];
    [self.incomeDescLab setText:KKLocalized(@"收入")];
    [self.monthDescLab setText:KKLocalized(@"月")];

    [self.payDescLab setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.payDescLab setTextColor:kColor_Text_White];
    [self.incomeDescLab setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.incomeDescLab setTextColor:kColor_Text_White];
    [self.monthDescLab setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.monthDescLab setTextColor:kColor_Text_White];

    [self.line setBackgroundColor:kColor_Text_White];

    [self.payLab setAttributedText:[NSAttributedString createMath:@"00.00" integer:[UIFont systemFontOfSize:AdjustFont(20)] decimal:[UIFont systemFontOfSize:AdjustFont(10)] color:kColor_Text_White]];
    [self.incomeLab setAttributedText:[NSAttributedString createMath:@"00.00" integer:[UIFont systemFontOfSize:AdjustFont(20)] decimal:[UIFont systemFontOfSize:AdjustFont(10)] color:kColor_Text_White]];

    [self.monthView addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
        [self routerEventWithName:HOME_MONTH_CLICK data:nil];
    }];

    [self.moneyShow setImage:[UIImage imageNamed:@"icon_pwd_show"] forState:UIControlStateNormal];
    [self.moneyShow setEnlargeEdgeWithTop:10 right:10 bottom:10 left:10];
    [self.moneyShow addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
        [self setMoneyDesensitization];
    }];

    UITapGestureRecognizer *tapPay = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(payLabelClick)];
    [_payLab addGestureRecognizer:tapPay];

    UITapGestureRecognizer *tapIncome = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(incomeLabelClick)];
    [_incomeLab addGestureRecognizer:tapIncome];
}


- (void)payLabelClick {
    [self routerEventWithName:HOME_PAY_CLICK data:@"0"];
}

- (void)incomeLabelClick {
    [self routerEventWithName:HOME_INCOME_CLICK data:@"1"];
}

/**
 * 设置金额是否可见
 */
- (void)setMoneyDesensitization {
    NSNumber *desensitization = [NSUserDefaults objectForKey:PIN_DESENSITIZATION];
    desensitization = @(![desensitization boolValue]);
    [NSUserDefaults setObject:desensitization forKey:PIN_DESENSITIZATION];
    [self setModels:_models];
}


#pragma mark - set
- (void)setDate:(NSDate *)date {
    _date = date;
    _yearLab.text = [@(date.year) description];
    _monthLab.text = [@(date.month) description];
}

- (void)setModels:(NSMutableArray<BookMonthModel *> *)models {
    _models = models;

    NSNumber *desensitization = [NSUserDefaults objectForKey:PIN_DESENSITIZATION];

    if ([desensitization boolValue]) {
        _payLab.text = @"****";
        _incomeLab.text = @"****";
        _payLab.textColor = kColor_Text_White;
        _incomeLab.textColor = kColor_Text_White;
        [_moneyShow setImage:[UIImage imageNamed:@"icon_pwd_hide"] forState:UIControlStateNormal];
    } else {
        UIFont *integer = [UIFont systemFontOfSize:AdjustFont(20)];
        UIFont *decimal = [UIFont systemFontOfSize:AdjustFont(10)];

        NSString *pay = [NSString stringWithFormat:@"%.2f", [[models valueForKeyPath:@"@sum.pay.floatValue"] floatValue]];
        NSString *income = [NSString stringWithFormat:@"%.2f", [[models valueForKeyPath:@"@sum.income.floatValue"] floatValue]];

        [_payLab setAttributedText:[NSAttributedString createMath:pay integer:integer decimal:decimal color:kColor_Text_White]];
        [_incomeLab setAttributedText:[NSAttributedString createMath:income integer:integer decimal:decimal color:kColor_Text_White]];
        [_moneyShow setImage:[UIImage imageNamed:@"icon_pwd_show"] forState:UIControlStateNormal];
    }
}

- (void)refresh {
    [self setModels:self.models];
}


@end
