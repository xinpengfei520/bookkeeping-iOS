/**
 * 主页点击 + 键盘页面
 * @author 郑业强 2018-12-18 创建文件
 */

#import "BKCKeyboard.h"
#import <AudioToolbox/AudioToolbox.h>

#define DATE_TAG 13         // 日期
#define PLUS_TAG 17         // 加
#define LESS_TAG 21         // 减
#define POINT_TAG 22        // 点
#define DELETE_TAG 24       // 删除
#define FINISH_TAG 25       // 完成
#define IS_MATH(tag) (tag >= 10 && tag <= 12) || (tag >= 14 && tag <= 16) || (tag >= 18 && tag <= 20) || tag == 23   // 是否是数字



#pragma mark - 声明
@interface BKCKeyboard()<UITextFieldDelegate>

// 顶部输入条（备注: + 输入框 + 金额 + 币种），代码创建（原 XIB 已迁移为代码布局）
@property (nonatomic, strong) UILabel *nameLab;
@property (nonatomic, strong) UITextField *markField;
@property (nonatomic, strong) UILabel *moneyLab;
@property (nonatomic, strong) UIView *textContent;

@property (nonatomic, strong) NSDate *currentDate;
@property (nonatomic, assign) BOOL isLess;          // 减
@property (nonatomic, assign) BOOL animation;       // 动画中

// 多币种
@property (nonatomic, strong) UIButton *currencyBtn;                    // 币种选择器
@property (nonatomic, strong) UILabel *rateLab;                         // 换算提示，仅外币时显示
@property (nonatomic, strong) NSLayoutConstraint *moneyBottomConstraint;// 让出 rateLab 的一行
@property (nonatomic, strong) NSLayoutConstraint *rateHeightConstraint; // 无提示时高度收成 0
@property (nonatomic, copy  ) NSString *currency;                       // 当前币种，默认 CNY
@property (nonatomic, assign) CGFloat exchangeRate;                     // 当前币种汇率，CNY 时为 0
@property (nonatomic, assign) BOOL rateLoading;                         // 汇率请求中
@property (nonatomic, assign) BOOL rateStale;                           // 服务端返回的是缓存旧汇率

@end


#pragma mark - 实现
@implementation BKCKeyboard


+ (instancetype)init {
    BKCKeyboard *view = [[BKCKeyboard alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_WIDTH / 5 * 4 + SafeAreaBottomHeight)];
    [view setHidden:YES];
    return view;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
        [self initUI];
    }
    return self;
}

// 迁移自 BKCKeyboard.xib：顶部 60pt 输入条 + 4×4 按钮栅格（1pt 间隙，底部让出安全区）。
// textContent 用 frame 定位（系统键盘弹起时 showKeyboard 会直接改它的 top），
// 输入条内部用 Auto Layout；按钮栅格全部 frame 计算。
- (void)buildSubviews {
    CGFloat textH = countcoordinatesX(60);

    // ---- 顶部输入条 ----
    _textContent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, textH)];
    [self addSubview:_textContent];

    _nameLab = [[UILabel alloc] init];
    _nameLab.translatesAutoresizingMaskIntoConstraints = NO;
    [_textContent addSubview:_nameLab];

    _markField = [[UITextField alloc] init];
    _markField.translatesAutoresizingMaskIntoConstraints = NO;
    _markField.returnKeyType = UIReturnKeyDone;
    _markField.delegate = self;
    [_textContent addSubview:_markField];

    _moneyLab = [[UILabel alloc] init];
    _moneyLab.translatesAutoresizingMaskIntoConstraints = NO;
    _moneyLab.textAlignment = NSTextAlignmentRight;
    _moneyLab.text = @"0";
    [_textContent addSubview:_moneyLab];

    [self buildCurrencyViews];

    [NSLayoutConstraint activateConstraints:@[
        [_nameLab.leadingAnchor constraintEqualToAnchor:_textContent.leadingAnchor constant:15],
        [_nameLab.topAnchor constraintEqualToAnchor:_textContent.topAnchor],
        [_nameLab.bottomAnchor constraintEqualToAnchor:_textContent.bottomAnchor],
        [_markField.leadingAnchor constraintEqualToAnchor:_nameLab.trailingAnchor constant:10],
        [_markField.topAnchor constraintEqualToAnchor:_textContent.topAnchor],
        [_markField.bottomAnchor constraintEqualToAnchor:_textContent.bottomAnchor],
        [_markField.trailingAnchor constraintEqualToAnchor:_moneyLab.leadingAnchor constant:-8],
        [_moneyLab.widthAnchor constraintEqualToConstant:120],      // 与原 XIB 一致的固定宽
    ]];

    // ---- 按钮栅格 ----
    // Row1: 7 8 9 日期 / Row2: 4 5 6 + / Row3: 1 2 3 - / Row4: . 0 删 完成
    // tag 顺序与原 XIB 相同（10~25，getMath / 各 *_TAG 宏依赖它）
    CGFloat gap = 1;
    CGFloat gridTop = textH + gap;
    CGFloat colW = (self.width - 3 * gap) / 4;
    CGFloat rowH = (self.height - SafeAreaBottomHeight - gridTop - 3 * gap) / 4;
    for (NSInteger i = 0; i < 16; i++) {
        NSInteger row = i / 4, col = i % 4;
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = 10 + i;
        btn.frame = CGRectMake(col * (colW + gap), gridTop + row * (rowH + gap), colW, rowH);
        [self addSubview:btn];
    }
}

- (void)initUI {
    [self borderForColor:kColor_BG borderWidth:1.f borderType:UIBorderSideTypeTop];
    [self setBackgroundColor:[UIColor systemBackgroundColor]];
    [self.textContent setBackgroundColor:[UIColor systemBackgroundColor]];
    [self setAnimation:NO];
    [self setIsLess:NO];
    [self setCurrentDate:[NSDate date]];

    [self.nameLab setText:KKLocalized(@"备注:")];
    [self.markField setPlaceholder:KKLocalized(@"点击写备注")];

    [self.nameLab setFont:[UIFont systemFontOfSize:AdjustFont(10)]];
    [self.nameLab setTextColor:kColor_Text_Black];

    [self.moneyLab setFont:[UIFont systemFontOfSize:AdjustFont(18)]];
    [self.markField setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.markField setTintColor:kColor_Main_Color];
    [self.markField setTextColor:kColor_Text_Black];

    [self createBtn];

    if (!_money) {
        _money = [NSMutableString string];
    }

    @weakify(self)
    [self kk_observeNotification:UIKeyboardWillShowNotification usingBlock:^(NSNotification *note) {
        @strongify(self)
        [self showKeyboard:note];
    }];
    [self kk_observeNotification:UIKeyboardWillHideNotification usingBlock:^(NSNotification *note) {
        @strongify(self)
        [self hideKeyboard:note];
    }];
}

- (void)createBtn {
    for (id obj in self.subviews) {
        if ([obj isKindOfClass:[UIButton class]] && [obj tag] >= 10) {
            UIButton *btn = obj;
            [btn.titleLabel setFont:[UIFont systemFontOfSize:AdjustFont(14)]];
            // 背景色
            if (btn.tag == FINISH_TAG) {
                [btn setBackgroundImage:[UIColor createImageWithColor:kColor_Main_Color] forState:UIControlStateNormal];
                [btn setBackgroundImage:[UIColor createImageWithColor:kColor_Main_Dark_Color] forState:UIControlStateHighlighted];
            }
            else {
                // 数字键背景：原本 kColor_White (固定白) → 深色模式下白底碰白字
                // (kColor_Text_Black 是 dynamic) 看不清。改 dynamic 色。
                [btn setBackgroundImage:[UIColor createImageWithColor:[UIColor systemBackgroundColor]] forState:UIControlStateNormal];
                [btn setBackgroundImage:[UIColor createImageWithColor:[UIColor secondarySystemBackgroundColor]] forState:UIControlStateHighlighted];
            }
            
            // 数字
            if (IS_MATH(btn.tag)) {
                NSInteger math = [self getMath:btn.tag];
                [btn setTitle:[@(math) description] forState:UIControlStateNormal];
                [btn setTitle:[@(math) description] forState:UIControlStateHighlighted];
            }
            else if (btn.tag == POINT_TAG) {
                [btn setTitle:@"." forState:UIControlStateNormal];
                [btn setTitle:@"." forState:UIControlStateHighlighted];
            }
            else if (btn.tag == DATE_TAG) {
                [btn setTitle:KKLocalized(@"今天") forState:UIControlStateNormal];
                [btn setTitle:KKLocalized(@"今天") forState:UIControlStateHighlighted];
            }
            else if (btn.tag == PLUS_TAG) {
                [btn setTitle:@"+" forState:UIControlStateNormal];
                [btn setTitle:@"+" forState:UIControlStateHighlighted];
            }
            else if (btn.tag == LESS_TAG) {
                [btn setTitle:@"-" forState:UIControlStateNormal];
                [btn setTitle:@"-" forState:UIControlStateHighlighted];
            }
            else if (btn.tag == FINISH_TAG) {
                [btn setTitle:KKLocalized(@"完成") forState:UIControlStateNormal];
                [btn setTitle:KKLocalized(@"完成") forState:UIControlStateHighlighted];
            }
            else if (btn.tag == DELETE_TAG) {
                [btn setImage:[UIImage imageNamed:@"keyboard_delete.png"] forState:UIControlStateNormal];
                btn.imageView.contentMode = UIViewContentModeScaleAspectFit;
            }
            
            if (btn.tag == FINISH_TAG) {
                [btn setTitleColor:kColor_Text_White forState:UIControlStateNormal];
            } else {
                [btn setTitleColor:kColor_Text_Black forState:UIControlStateNormal];
            }
            [btn setTitleColor:kColor_Text_Gary forState:UIControlStateHighlighted];
            
            [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
}


#pragma mark - 多币种
// 输入条的右半部分：[金额][币种] + 金额下方的 rateLab —— 币种跟在金额后面，
// 读作"25.50 ¥"，默认就是人民币，用户不点它就不需要做任何选择。
- (void)buildCurrencyViews {
    if (_currencyBtn) {
        return;     // 子视图只建一次
    }
    _currency = KKCurrencyCNY;
    _exchangeRate = 0;

    // 圆角浅底的小胶囊，让用户一眼看出这是可以点的按钮
    _currencyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _currencyBtn.translatesAutoresizingMaskIntoConstraints = NO;
    UIButtonConfiguration *cfg = [UIButtonConfiguration filledButtonConfiguration];
    cfg.cornerStyle = UIButtonConfigurationCornerStyleMedium;
    cfg.contentInsets = NSDirectionalEdgeInsetsMake(3, 5, 3, 5);
    cfg.baseBackgroundColor = [kColor_Main_Color colorWithAlphaComponent:0.12f];
    cfg.baseForegroundColor = kColor_Main_Color;
    cfg.titleTextAttributesTransformer = ^NSDictionary<NSAttributedStringKey, id> *(NSDictionary<NSAttributedStringKey, id> *incoming) {
        NSMutableDictionary *attrs = [incoming mutableCopy];
        attrs[NSFontAttributeName] = [UIFont systemFontOfSize:AdjustFont(11)];
        return attrs;
    };
    _currencyBtn.configuration = cfg;
    [_currencyBtn addTarget:self action:@selector(currencyBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.textContent addSubview:_currencyBtn];

    _rateLab = [[UILabel alloc] init];
    _rateLab.translatesAutoresizingMaskIntoConstraints = NO;
    [_rateLab setFont:[UIFont systemFontOfSize:AdjustFont(9) weight:UIFontWeightLight]];
    [_rateLab setTextColor:kColor_Text_Gary];
    [_rateLab setTextAlignment:NSTextAlignmentRight];
    [_rateLab setHidden:YES];
    [self.textContent addSubview:_rateLab];

    // 无提示时 rateLab 高度收成 0、金额行占满 60pt；有提示时两者一起让出 16pt，
    // 避免空 label 的固有高度顶破容器底边。
    _moneyBottomConstraint = [self.moneyLab.bottomAnchor constraintEqualToAnchor:self.textContent.bottomAnchor];
    _rateHeightConstraint = [_rateLab.heightAnchor constraintEqualToConstant:0];
    [NSLayoutConstraint activateConstraints:@[
        _rateHeightConstraint,
        [self.moneyLab.topAnchor constraintEqualToAnchor:self.textContent.topAnchor],
        [self.moneyLab.trailingAnchor constraintEqualToAnchor:_currencyBtn.leadingAnchor constant:-8],
        _moneyBottomConstraint,
        [_currencyBtn.trailingAnchor constraintEqualToAnchor:self.textContent.trailingAnchor constant:-countcoordinatesX(15)],
        [_currencyBtn.centerYAnchor constraintEqualToAnchor:self.moneyLab.centerYAnchor],
        [_rateLab.topAnchor constraintEqualToAnchor:self.moneyLab.bottomAnchor],
        [_rateLab.trailingAnchor constraintEqualToAnchor:self.textContent.trailingAnchor constant:-countcoordinatesX(15)],
        [_rateLab.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.textContent.leadingAnchor constant:countcoordinatesX(15)],
    ]];

    [self reloadCurrencyUI];
}

// 点击币种：人民币 / 美元 / 港币 / 新加坡元
- (void)currencyBtnClick {
    UIViewController *vc = self.viewController;
    if (vc == nil) {
        return;
    }
    [self.markField endEditing:YES];

    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:KKLocalized(@"选择币种")
                                                                  message:nil
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSString *code in [KKCurrency supportedCodes]) {
        NSString *title = [NSString stringWithFormat:@"%@ %@", [KKCurrency nameForCode:code], [KKCurrency badgeForCode:code]];
        UIAlertAction *action = [UIAlertAction actionWithTitle:title
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *a) {
            [self selectCurrency:code];
        }];
        [sheet addAction:action];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:KKLocalized(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    // iPad / Mac Catalyst 上 actionSheet 必须有锚点，iPhone 上设了也无害
    sheet.popoverPresentationController.sourceView = self.currencyBtn;
    sheet.popoverPresentationController.sourceRect = self.currencyBtn.bounds;
    [vc presentViewController:sheet animated:YES completion:nil];
}

- (void)selectCurrency:(NSString *)code {
    if ([code isEqualToString:_currency]) {
        return;
    }
    _currency = code;
    _exchangeRate = 0;
    _rateStale = NO;
    [self reloadCurrencyUI];
    [self requestRateIfNeeded];
}

// 币种或记账日期变了都要重新取汇率：补记旧账要用当天的汇率
- (void)requestRateIfNeeded {
    if (![KKCurrency isForeignCode:_currency]) {
        return;
    }
    _rateLoading = YES;
    [self reloadCurrencyUI];
    if (self.rateRequest) {
        self.rateRequest(_currency, self.currentDate);
    }
}

- (void)setExchangeRate:(CGFloat)rate forCurrency:(NSString *)currency stale:(BOOL)stale {
    // 请求返回时用户可能已经改了币种，过期回包直接丢掉
    if (![currency isEqualToString:_currency]) {
        return;
    }
    _rateLoading = NO;
    _rateStale = stale;
    _exchangeRate = rate;

    if (rate <= 0) {
        // 拿不到汇率就退回人民币，绝不静默按 1:1 记一笔外币
        _currency = KKCurrencyCNY;
        _rateStale = NO;
        [self reloadCurrencyUI];
        [self showTextHUD:KKLocalized(@"汇率获取失败，已切回人民币，请稍后重试") delay:2.f];
        return;
    }
    [self reloadCurrencyUI];
    if (stale) {
        [self showTextHUD:KKLocalized(@"当前汇率可能不是最新，请确认后再记账") delay:2.f];
    }
}

// 币种按钮标题 + 换算提示行
- (void)reloadCurrencyUI {
    UIButtonConfiguration *cfg = self.currencyBtn.configuration;
    cfg.title = [NSString stringWithFormat:@"%@ ▾", [KKCurrency badgeForCode:_currency]];
    self.currencyBtn.configuration = cfg;

    BOOL foreign = [KKCurrency isForeignCode:_currency];
    CGFloat amount = [self currentAmount];
    NSString *hint = nil;
    // 还没输金额（或输了 0）时不占这一行：没有金额可换算，提示也没有意义
    if (foreign && amount > 0) {
        if (_rateLoading) {
            hint = KKLocalized(@"汇率获取中…");
        } else if (_exchangeRate > 0) {
            CGFloat cny = [KKCurrency cnyPriceForAmount:amount rate:_exchangeRate];
            // 提交前让用户看到换算结果：US$5.20 ≈ ¥35.11（1 USD = 6.752650 CNY）
            hint = [NSString stringWithFormat:@"%@ ≈ ¥%@（%@）",
                    [KKCurrency displayAmount:amount code:_currency],
                    [KKCurrency formatAmount:cny],
                    [KKCurrency displayRate:_exchangeRate code:_currency]];
            if (_rateStale) {
                hint = [KKLocalized(@"汇率可能不是最新 · ") stringByAppendingString:hint];
            }
        }
    }
    [self.rateLab setText:hint];
    [self.rateLab setHidden:(hint.length == 0)];
    // 有提示时把金额行压上去，给提示让出一行
    CGFloat rateHeight = (hint.length == 0) ? 0 : countcoordinatesX(16);
    [self.moneyBottomConstraint setConstant:-rateHeight];
    [self.rateHeightConstraint setConstant:rateHeight];
}

// 当前输入框里的金额（已计算完的数值，含加减式子时取展示值）
- (CGFloat)currentAmount {
    return [_moneyLab.text doubleValue];
}


#pragma mark - 动画
- (void)show {
    if (_animation == YES) {
        return;
    }
    _animation = YES;
    
    [self setHidden:NO];
    [UIView animateWithDuration:.3f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self setTop:SCREEN_HEIGHT - self.height];
    } completion:^(BOOL finished) {
        [self setAnimation:NO];
    }];
}

- (void)hide {
    if (_animation == YES) {
        return;
    }
    _animation = YES;
    
    [self.markField endEditing:YES];
    [self setHidden:NO];
    [UIView animateWithDuration:.3f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self setTop:SCREEN_HEIGHT];
    } completion:^(BOOL finished) {
        [self setAnimation:NO];
    }];
}


#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - 点击
- (void)btnClick:(UIButton *)btn {
    // 按键音效
    AudioServicesPlaySystemSound(1104);
    // 数字
    [self mathBtnClick:btn];
    // 点
    [self pointBtnClick:btn];
    // 加
    [self plusBtnClick:btn];
    // 减
    [self lessBtnClick:btn];
    // 时间
    [self dateBtnClick:btn];
    // 删除
    [self deleteBtnClick:btn];
    // 完成/等于
    [self calculationClick:btn];
    // 刷新
    [self reloadCompleteButton];
    // 计算
    [self calculationMath];
    // 外币换算提示跟着金额实时更新
    [self reloadCurrencyUI];
}

// 数字
- (void)mathBtnClick:(UIButton *)btn {
    // 数字
    if (IS_MATH(btn.tag)) {
        
        NSInteger math = [self getMath:btn.tag];
        NSString *str = ({
            NSString *str;
            if ([_money componentsSeparatedByString:@"+"].count == 2) {
                str = [_money componentsSeparatedByString:@"+"][1];
            } else {
                str = _money;
            }
            str;
        });
        
        // 是否可以输入
        if ([self isAllowMath:str]) {
            if (_money.length == 0 || [_money isEqualToString:@"0"]) {
                _money = [NSMutableString stringWithString:[@(math) description]];
            } else {
                [_money appendString:[@(math) description]];
            }
            [self setMoney:_money];
        }
    }
}

// 点
- (void)pointBtnClick:(UIButton *)btn {
    // 点
    if (btn.tag == POINT_TAG) {
        // 是否可以输入
        if ([self isAllowPoint:_money]) {
            if (_money.length == 0) {
                [_money appendString:@"0"];
            }
            [_money appendString:@"."];
            [self setMoney:_money];
        }
    }
}

// 加
- (void)plusBtnClick:(UIButton *)btn {
    // 加
    if (btn.tag == PLUS_TAG) {
        if (_money.length == 0) {
            _money = [NSMutableString stringWithString:@"0"];
        }
        
        if ([self isAllowPlusOrLess:_money]) {
            [_money appendString:@"+"];
            [self setMoney:_money];
        }
    }
}

// 减
- (void)lessBtnClick:(UIButton *)btn {
    // 减
    if (btn.tag == LESS_TAG) {
        if (_money.length == 0) {
            _money = [NSMutableString stringWithString:@"0"];
        }
        
        if ([self isAllowPlusOrLess:_money]) {
            [_money appendString:@"-"];
            [self setMoney:_money];
        }
    }
}

// 选择时间
- (void)dateBtnClick:(UIButton *)btn {
    // 时间
    if (btn.tag == DATE_TAG) {
        @weakify(self)
        NSDate *date = [NSDate date];
        NSDate *min = [NSDate br_setYear:2000 month:1 day:1];
        NSDate *max = [NSDate br_setYear:date.year + 3 month:12 day:31];
        
        // 1.创建日期选择器
        BRDatePickerView *datePickerView = [[BRDatePickerView alloc]init];
        // 2.设置属性
        BRPickerStyle *style = [[BRPickerStyle alloc] init];
        style.cancelBtnTitle = KKLocalized(@"取消");
        style.doneBtnTitle = KKLocalized(@"确定");
        datePickerView.pickerStyle = style;
        datePickerView.pickerMode = BRDatePickerModeYMD;
        datePickerView.title = KKLocalized(@"选择日期");
        datePickerView.selectDate = self.currentDate;
        datePickerView.minDate = min;
        datePickerView.maxDate = max;
        datePickerView.isAutoSelect = false;
        datePickerView.resultBlock = ^(NSDate *selectDate, NSString *selectValue) {
            KKLog(@"选择的值：%@", selectValue);
            @strongify(self)
            [self setCurrentDate:({
                NSDateFormatter *fora = [[NSDateFormatter alloc] init];
                [fora setDateFormat:@"yyyy-MM-dd"];
                NSDate *date = [fora dateFromString:selectValue];
                date;
            })];
            selectValue = [self.currentDate isToday] ? KKLocalized(@"今天") : selectValue;
            [btn setTitle:selectValue forState:UIControlStateNormal];
            [btn setTitle:selectValue forState:UIControlStateHighlighted];
            [btn.titleLabel setFont:[UIFont systemFontOfSize:AdjustFont(12)]];
            // 补记旧账要用记账当天的汇率，日期一变就重新取
            [self requestRateIfNeeded];
        };

        // 3.显示
        [datePickerView show];
    }
}

// 删除
- (void)deleteBtnClick:(UIButton *)btn {
    if (btn.tag == DELETE_TAG) {
        if (_money.length > 1) {
            [_money deleteCharactersInRange:NSMakeRange(_money.length - 1, 1)];
            [self setMoney:_money];
        } else {
            _money = [NSMutableString string];
            _moneyLab.text = @"0";
        }
    }
}

// 计算
- (void)calculationClick:(UIButton *)btn {
    if (btn.tag == FINISH_TAG) {
        [_money appendString:@"="];
        [self setMoney:_money];
        [self calculationMath];
    }
    if ([btn.titleLabel.text isEqualToString:KKLocalized(@"完成")]) {
        CGFloat moneyValue = [_moneyLab.text floatValue];
        if (moneyValue == .0f) {
            [self showTextHUD:KKLocalized(@"请输入金额") delay:1];
            return;
        }
        // 选了外币却没拿到汇率：宁可拦住，也不能静默按 1:1 记账
        if ([KKCurrency isForeignCode:_currency] && _exchangeRate <= 0) {
            [self showTextHUD:_rateLoading ? KKLocalized(@"汇率获取中…") : KKLocalized(@"汇率获取失败，请稍后重试") delay:1.5f];
            return;
        }

        if (self.complete) {
            self.complete(_moneyLab.text, _markField.text, self.currentDate, _currency, _exchangeRate);
        }
    }
}

// 根据btn.tag 返回数字
- (CGFloat)getMath:(NSInteger)tag {
    if (tag >= 10 && tag <= 12) {
        return tag - 3;
    }
    else if (tag >= 14 && tag <= 16) {
        return tag - 10;
    }
    else if (tag >= 18 && tag <= 20) {
        return tag - 17;
    }
    else if (tag == 23) {
        return 0;
    }
    return 0;
}

// 刷新完成按钮
- (void)reloadCompleteButton {
    if (_money.length == 0) {
        UIButton *btn = [self viewWithTag:FINISH_TAG];
        [btn setTitle:KKLocalized(@"完成") forState:UIControlStateNormal];
        [btn setTitle:KKLocalized(@"完成") forState:UIControlStateHighlighted];
    } else {
        NSString *subMoney = [_money substringFromIndex:1];
        BOOL condition1 = ([subMoney containsString:@"+"] || [subMoney containsString:@"-"]) && ![_money hasSuffix:@"+"] && ![_money hasSuffix:@"-"];
        if (condition1) {
            UIButton *btn = [self viewWithTag:FINISH_TAG];
            [btn setTitle:@"=" forState:UIControlStateNormal];
            [btn setTitle:@"=" forState:UIControlStateHighlighted];
        } else {
            UIButton *btn = [self viewWithTag:FINISH_TAG];
            [btn setTitle:KKLocalized(@"完成") forState:UIControlStateNormal];
            [btn setTitle:KKLocalized(@"完成") forState:UIControlStateHighlighted];
        }
    }
}


// 计算
- (void)calculationMath {
    if (_money.length == 0) {
        return;
    }
    
    BOOL condition1 = [_money hasSuffix:@"="];
    BOOL condition2 = [_money componentsSeparatedByString:@"+"].count == 3;
    BOOL condition3 = ([_money hasPrefix:@"-"] && [NSString getDuplicateSubStrCountInCompleteStr:_money withSubStr:@"-"] == 3) ||
                      (![_money hasPrefix:@"-"] && [NSString getDuplicateSubStrCountInCompleteStr:_money withSubStr:@"-"] == 2);
    BOOL condition4 = [_money containsString:@"+"] &&
                      (([_money hasPrefix:@"-"] && [NSString getDuplicateSubStrCountInCompleteStr:_money withSubStr:@"-"] == 2) ||
                       (![_money hasPrefix:@"-"] && [NSString getDuplicateSubStrCountInCompleteStr:_money withSubStr:@"-"] == 1));
    if (condition1 == true || condition2 == true || condition3 == true || condition4 == true) {
        NSMutableString *strm = [NSMutableString stringWithString:[NSString calcComplexFormulaString:_money]];
        // 没小数
        if (![self hasDecimal:strm]) {
            strm = [NSMutableString stringWithString:[strm componentsSeparatedByString:@"."][0]];
        }
        // 加
        if ([_money hasSuffix:@"+"]) {
            [strm appendString:@"+"];
        }
        // 减
        if ([_money hasSuffix:@"-"]) {
            [strm appendString:@"-"];
        }
//        // 没加减
//        if (![_money hasSuffix:@"+"] && ![_money hasSuffix:@"-"]) {
//            [self reloadCompleteButton];
//        }
        
        [self setMoney:strm];
    }
}

// 两数加减
- (NSString *)calculation:(NSString *)str1 math:(NSString *)str2 isPlus:(BOOL)isPlus {
    CGFloat number1 = [str1 floatValue];
    CGFloat number2 = [str2 floatValue];
    NSString *newNumber = [NSString stringWithFormat:@"%.2f", (isPlus ? number1 + number2 : number1 - number2)];
    if (![self hasDecimal:newNumber]) {
        newNumber = [newNumber substringWithRange:NSMakeRange(0, newNumber.length - 3)];
    }
    return newNumber;
}

// 是否有小数
- (BOOL)hasDecimal:(NSString *)number {
    NSArray<NSString *> *arr = [number componentsSeparatedByString:@"."];
    NSString *decimal = arr[1];
    if ([decimal integerValue] == 0) {
        return false;
    }
    return true;
}

// 获取字符串中的数字
- (NSArray<NSString *> *)getNumberWithString:(NSString *)string {
    // 第一个数是负数
    BOOL isNegative = [[string substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"-"];
    if (isNegative == true) {
        string = [string substringFromIndex:1];
    }
    
    NSString *lastStr = [string substringWithRange:NSMakeRange(string.length - 1, 1)];
    if ([lastStr isEqualToString:@"+"] || [lastStr isEqualToString:@"-"]) {
        string = [string substringToIndex:string.length - 1];
    }
    
    NSMutableArray *arrm;
    // 加法
    if ([string containsString:@"+"]) {
        arrm = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@"+"]];
    }
    // 减法
    else if ([string containsString:@"-"]) {
        arrm = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@"-"]];
    }
    // 第一个数是负数
    if (isNegative == true) {
        NSString *str = [NSString stringWithFormat:@"-%@", arrm[0]];
        [arrm replaceObjectAtIndex:0 withObject:str];
    }
    KKLog(@"%@", arrm);
    KKLog(@"123");
    return @[];
}

// 是否可以输入数字
- (BOOL)isAllowMath:(NSString *)str {
    // 超过10位
    if (_money.length >= 15) {
        return false;
    }
    
    if (!str || str.length == 0) {
        return true;
    }
    
    NSString *lastStr = [str substringFromIndex:str.length - 1];
    // 最后输入的是数字
    if ([lastStr isEqualToString:@"+"] || [lastStr isEqualToString:@"-"] || [lastStr isEqualToString:@"="]) {
        return true;
    }
    // 最后输入的是数字/点
    else {
        if ([str containsString:@"+"]) {
            str = [str componentsSeparatedByString:@"+"][1];
        } else if ([str containsString:@"-"]) {
            str = [str componentsSeparatedByString:@"-"][1];
        }
        NSArray<NSString *> *arr = [str componentsSeparatedByString:@"."];
        if (arr.count != 2 || (arr.count == 2 && arr[1].length < 2)) {
            return true;
        }
        return false;
    }
}

// 是否可以输入点
- (BOOL)isAllowPoint:(NSString *)str {
    // 超过10位
    if (_money.length >= 15) {
        return false;
    }
    
    // 是否可以输入
    for (int i=0; i<3; i++) {
        str = [str containsString:@"+"] ? [str componentsSeparatedByString:@"+"][1] : str;
        str = [str containsString:@"-"] ? [str componentsSeparatedByString:@"-"][1] : str;
    }
    if (![str containsString:@"."]) {
        return true;
    }
    return false;
}

// 是否可以输入加号减号
- (BOOL)isAllowPlusOrLess:(NSString *)str {
    NSString *lastStr = [str substringWithRange:NSMakeRange(_money.length - 1, 1)];
    if ([lastStr isEqualToString:@"+"] || [lastStr isEqualToString:@"-"]) {
        return false;
    }
    return true;
}


#pragma mark - set
- (void)setMoney:(NSMutableString *)money {
    _money = money;
    _moneyLab.text = money;
}

- (void)setModel:(BookDetailModel *)model {
    _model = model;
    NSString *key = [NSString stringWithFormat:@"%ld-%02ld-%02ld", model.year, model.month, model.day];
    [self.markField setText:model.mark];
    // 编辑外币记录：输入框里放回**原始外币金额**，币种与当时的汇率一并还原，
    // 用户不动金额时提交回去的三个字段与原来一致，不会写出自相矛盾的数据。
    if ([model isForeignCurrency]) {
        _currency = model.currency;
        _exchangeRate = model.exchangeRate;
        _rateStale = NO;
        [self setMoney:[KKCurrency formatAmount:model.originalPrice].mutableCopy];
    } else {
        _currency = KKCurrencyCNY;
        _exchangeRate = 0;
        [self setMoney:[model getPriceStr].mutableCopy];
    }
    [self reloadCurrencyUI];
    [self setCurrentDate:[NSDate dateWithYMD:key]];

    UIButton *btn = [self viewWithTag:DATE_TAG];
    NSString *selectValue = [self.currentDate isToday] ? KKLocalized(@"今天") : key;
    [btn setTitle:selectValue forState:UIControlStateNormal];
    [btn setTitle:selectValue forState:UIControlStateHighlighted];
    [btn.titleLabel setFont:[UIFont systemFontOfSize:AdjustFont(12)]];
}

- (void)setMark:(MarkModel *)model {
    [self.markField setText:model.markName];
}

#pragma mark - 系统键盘通知
- (void)showKeyboard:(NSNotification *)not {
    NSTimeInterval time = [not.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    // UIKeyboardFrameBeginUserInfoKey,UIKeyboardFrameEndUserInfoKey
    // 对应的 Value 是个 NSValue 对象，内部包含 CGRect 结构，分别为键盘起始时和终止时的位置信息
    // 此处应该使用终止时的位置，因为弹起软键盘的时候位置有变化
    CGFloat keyHeight = [not.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;

    // countcoordinatesX(44) 是 markView 的高度。textContent 是 frame 定位的，
    // 直接改 top 即可，重新布局不会把它拍回去。
    [UIView animateWithDuration:time delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.textContent setTop:(self.height - keyHeight) - countcoordinatesX(60) - countcoordinatesX(44)];
    } completion:^(BOOL finished) {

    }];
}

- (void)hideKeyboard:(NSNotification *)not {
    NSTimeInterval time = [not.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    [UIView animateWithDuration:time delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.textContent setTop:0];
    } completion:^(BOOL finished) {

    }];
}


@end
