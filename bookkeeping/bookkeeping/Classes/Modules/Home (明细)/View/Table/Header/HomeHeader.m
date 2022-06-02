/**
 * 头视图
 * @author 郑业强 2018-12-16 创建文件
 */

#import "HomeHeader.h"
#import "HOME_EVENT.h"
#import "UIButton+EnlargeTouchArea.h"

#pragma mark - 声明
@interface HomeHeader()
@property (weak, nonatomic) IBOutlet UILabel *yearLab;
@property (weak, nonatomic) IBOutlet UILabel *incomeDescLab;
@property (weak, nonatomic) IBOutlet UILabel *payDescLab;
@property (weak, nonatomic) IBOutlet UILabel *monthLab;
@property (weak, nonatomic) IBOutlet UILabel *monthDescLab;
@property (weak, nonatomic) IBOutlet UILabel *incomeLab;
@property (weak, nonatomic) IBOutlet UILabel *payLab;
@property (weak, nonatomic) IBOutlet UIView *line;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lineConstraintL;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *getConstraintL;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *setConstraintL;
@property (weak, nonatomic) IBOutlet UIView *monthView;
@property (weak, nonatomic) IBOutlet UIButton *moneyShow;
@end


#pragma mark - 实现
@implementation HomeHeader


- (void)initUI {
    [self setBackgroundColor:kColor_Main_Color];
    [self.yearLab setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.yearLab setTextColor:kColor_Text_White];
    [self.monthLab setFont:[UIFont systemFontOfSize:AdjustFont(20) weight:UIFontWeightLight]];
    [self.monthLab setTextColor:kColor_Text_White];
    
    [self.payDescLab setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.payDescLab setTextColor:kColor_Text_White];
    [self.incomeDescLab setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.incomeDescLab setTextColor:kColor_Text_White];
    [self.monthDescLab setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.monthDescLab setTextColor:kColor_Text_White];
    
    [self.line setBackgroundColor:kColor_Text_White];
    [self.lineConstraintL setConstant:SCREEN_WIDTH / 4];
    
    [self.payLab setAttributedText:[NSAttributedString createMath:@"00.00" integer:[UIFont systemFontOfSize:AdjustFont(20)] decimal:[UIFont systemFontOfSize:AdjustFont(10)] color:kColor_Text_White]];
    [self.incomeLab setAttributedText:[NSAttributedString createMath:@"00.00" integer:[UIFont systemFontOfSize:AdjustFont(20)] decimal:[UIFont systemFontOfSize:AdjustFont(10)] color:kColor_Text_White]];
    
    [self.monthView addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
        [self routerEventWithName:HOME_MONTH_CLICK data:nil];
    }];
    
    // 增大可点击区域，上下左右各 10
    [self.moneyShow setEnlargeEdgeWithTop:10 right:10 bottom:10 left:10];
    [self.moneyShow addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
        [self setMoneyDesensitization];
    }];
    
    UITapGestureRecognizer *tapGestureRecognizer1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(payLabelClick)];
    [_payLab addGestureRecognizer:tapGestureRecognizer1];
    _payLab.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tapGestureRecognizer2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(incomeLabelClick)];
    [_incomeLab addGestureRecognizer:tapGestureRecognizer2];
    _incomeLab.userInteractionEnabled = YES;
}

- (void)payLabelClick {
    [self routerEventWithName:HOME_PAY_CLICK data:nil];
}

- (void)incomeLabelClick {
    [self routerEventWithName:HOME_INCOME_CLICK data:nil];
}

/**
 * 设置金额是否可见
 */
- (void) setMoneyDesensitization {
    // 从缓存中取出 PIN_DESENSITIZATION 的值，如果没有则默认为 0
    NSNumber *desensitization = [NSUserDefaults objectForKey:PIN_DESENSITIZATION];
    // 当点击后，取反并重新保存
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

- (void)setModels:(NSMutableArray<BKMonthModel *> *)models {
    _models = models;
    
    // 从缓存中取出 PIN_DESENSITIZATION 的值，如果没有则默认为 0 (false)
    NSNumber *desensitization = [NSUserDefaults objectForKey:PIN_DESENSITIZATION];
    
    // 脱敏显示
    if ([desensitization boolValue]) {
        _payLab.text = @"***";
        _incomeLab.text = @"***";
        _payLab.textColor = kColor_Text_White;
        _incomeLab.textColor = kColor_Text_White;
        [_moneyShow setImage:[UIImage imageNamed:@"icon_pwd_hide"] forState:UIControlStateNormal];
        
    // 不脱敏显示
    }else{
        UIFont *integer = [UIFont systemFontOfSize:AdjustFont(20)];
        UIFont *decimal = [UIFont systemFontOfSize:AdjustFont(10)];

        NSString *pay = [NSString stringWithFormat:@"%.2f", [[models valueForKeyPath:@"@sum.pay.floatValue"] floatValue]];
        NSString *income = [NSString stringWithFormat:@"%.2f", [[models valueForKeyPath:@"@sum.income.floatValue"] floatValue]];

        [_payLab setAttributedText:[NSAttributedString createMath:pay integer:integer decimal:decimal color:kColor_Text_White]];
        [_incomeLab setAttributedText:[NSAttributedString createMath:income integer:integer decimal:decimal color:kColor_Text_White]];
    }
}

//- (void)setModel:(BKModel *)model {
//    _model = model;
//    NSString *pay = [NSString stringWithFormat:@"%.2f", model.pay];
//    NSString *income = [NSString stringWithFormat:@"%.2f", model.income];
//    [_payLab setAttributedText:[NSAttributedString createMath:pay integer:[UIFont systemFontOfSize:AdjustFont(14)] decimal:[UIFont systemFontOfSize:AdjustFont(12)]]];
//    [_incomeLab setAttributedText:[NSAttributedString createMath:income integer:[UIFont systemFontOfSize:AdjustFont(14)] decimal:[UIFont systemFontOfSize:AdjustFont(12)]]];
//}


@end
