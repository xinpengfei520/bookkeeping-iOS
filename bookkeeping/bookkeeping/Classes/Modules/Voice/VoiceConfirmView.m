//
//  VoiceConfirmView.m
//  bookkeeping
//

#import "VoiceConfirmView.h"
#import "KKBookTextParser.h"
#import "BKCIncomeModel.h"
#import "BookDetailModel.h"

static const CGFloat kPadding = 20;
static const CGFloat kRowHeight = 54;

#pragma mark - 声明
@interface VoiceConfirmView () <UITextFieldDelegate>

@property (nonatomic, strong) KKParsedBookEntry *entry;
@property (nonatomic, strong) NSArray<BKCModel *> *categories;
@property (nonatomic, copy  ) void (^confirmBlock)(BookDetailModel *model);

@property (nonatomic, strong) UIView *dimView;
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UITextField *amountField;
@property (nonatomic, strong) UIScrollView *chipScroll;
@property (nonatomic, strong) NSArray<UIButton *> *chips;
@property (nonatomic, strong) UIButton *dateBtn;
@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, strong) UITextField *markField;
@property (nonatomic, assign) NSInteger selectedIndex;   // categories 下标

@end

#pragma mark - 实现
@implementation VoiceConfirmView

+ (void)showWithEntry:(KKParsedBookEntry *)entry categories:(NSArray<BKCModel *> *)categories confirm:(void (^)(BookDetailModel *))confirm {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window || categories.count == 0) return;
    VoiceConfirmView *view = [[VoiceConfirmView alloc] initWithFrame:window.bounds];
    view.entry = entry;
    view.categories = categories;
    view.confirmBlock = confirm;
    [view buildSubviews];
    [window addSubview:view];
    [view present];
}

#pragma mark - build

- (void)buildSubviews {
    // 默认选中解析结果；没匹配到就落在第一个支出类别上
    _selectedIndex = 0;
    for (NSInteger i = 0; i < (NSInteger)_categories.count; i++) {
        if (_categories[i].Id == _entry.categoryId) { _selectedIndex = i; break; }
    }

    _dimView = [[UIView alloc] initWithFrame:self.bounds];
    _dimView.backgroundColor = RGBA(0, 0, 0, 0.4);
    [_dimView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)]];
    [self addSubview:_dimView];

    _card = [[UIView alloc] init];
    _card.backgroundColor = KKDynamicColor([UIColor whiteColor], RGBA(44, 44, 46, 1));
    _card.layer.cornerRadius = 16;
    _card.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    [self addSubview:_card];

    CGFloat width = self.width;
    CGFloat y = 18;

    // 标题 + 关闭
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(kPadding, y, width - kPadding * 2, 22)];
    title.text = KKLocalized(@"确认记账");
    title.font = [UIFont boldSystemFontOfSize:17];
    title.textColor = kColor_Text_Black;
    title.textAlignment = NSTextAlignmentCenter;
    [_card addSubview:title];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(width - 52, y - 10, 44, 44);
    [close setTitle:@"✕" forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont systemFontOfSize:17];
    [close setTitleColor:kColor_Text_Gary forState:UIControlStateNormal];
    [close addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [_card addSubview:close];
    y = title.bottom + 8;

    // 原始识别文本
    if (_entry.rawText.length) {
        UILabel *raw = [[UILabel alloc] init];
        raw.text = [NSString stringWithFormat:@"“%@”", _entry.rawText];
        raw.font = [UIFont systemFontOfSize:13];
        raw.textColor = kColor_Text_Gary;
        raw.textAlignment = NSTextAlignmentCenter;
        raw.numberOfLines = 2;
        CGSize size = [raw sizeThatFits:CGSizeMake(width - kPadding * 2, CGFLOAT_MAX)];
        raw.frame = CGRectMake(kPadding, y, width - kPadding * 2, MIN(size.height, 36));
        [_card addSubview:raw];
        y = raw.bottom + 6;
    }

    // 金额
    y = [self addSeparatorAt:y];
    UILabel *amountLabel = [self fieldLabel:KKLocalized(@"金额") y:y];
    [_card addSubview:amountLabel];
    _amountField = [[UITextField alloc] initWithFrame:CGRectMake(100, y, width - 100 - kPadding, kRowHeight)];
    _amountField.font = [UIFont boldSystemFontOfSize:24];
    _amountField.textColor = kColor_Text_Black;
    _amountField.textAlignment = NSTextAlignmentRight;
    _amountField.keyboardType = UIKeyboardTypeDecimalPad;
    _amountField.delegate = self;
    if (_entry.price > 0) {
        _amountField.text = [NSString stringWithFormat:@"%.2f", _entry.price];
    } else {
        // 没听出金额：占位符红字提醒补一下
        _amountField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:KKLocalized(@"没听出金额，请补一下")
            attributes:@{NSForegroundColorAttributeName: kColor_Text_Red, NSFontAttributeName: [UIFont systemFontOfSize:15]}];
    }
    [_card addSubview:_amountField];
    y += kRowHeight;

    // 类别（横向滚动 chips）
    y = [self addSeparatorAt:y];
    UILabel *cateLabel = [self fieldLabel:KKLocalized(@"类别") y:y];
    [_card addSubview:cateLabel];
    _chipScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(76, y + (kRowHeight - 32) / 2, width - 76, 32)];
    _chipScroll.showsHorizontalScrollIndicator = NO;
    _chipScroll.contentInset = UIEdgeInsetsMake(0, 0, 0, kPadding);
    [_card addSubview:_chipScroll];
    [self buildChips];
    y += kRowHeight;

    // 日期：卡片挂在 window 上，系统 Compact UIDatePicker 找不到 VC 弹日历，点了没反应。
    // 改成可点按钮 + 与记账键盘同一套 BRDatePickerView。
    y = [self addSeparatorAt:y];
    UILabel *dateLabel = [self fieldLabel:KKLocalized(@"日期") y:y];
    [_card addSubview:dateLabel];
    NSDateComponents *comp = [[NSDateComponents alloc] init];
    comp.year = _entry.year; comp.month = _entry.month; comp.day = _entry.day; comp.hour = 12;
    _selectedDate = [[NSCalendar currentCalendar] dateFromComponents:comp] ?: [NSDate date];
    _dateBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _dateBtn.frame = CGRectMake(100, y, width - 100 - kPadding, kRowHeight);
    _dateBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    _dateBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [_dateBtn setTitleColor:kColor_Text_Black forState:UIControlStateNormal];
    [_dateBtn addTarget:self action:@selector(dateBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [_card addSubview:_dateBtn];
    [self reloadDateBtn];
    y += kRowHeight;

    // 备注
    y = [self addSeparatorAt:y];
    UILabel *markLabel = [self fieldLabel:KKLocalized(@"备注") y:y];
    [_card addSubview:markLabel];
    _markField = [[UITextField alloc] initWithFrame:CGRectMake(100, y, width - 100 - kPadding, kRowHeight)];
    _markField.font = [UIFont systemFontOfSize:15];
    _markField.textColor = kColor_Text_Black;
    _markField.textAlignment = NSTextAlignmentRight;
    _markField.placeholder = KKLocalized(@"选填");
    _markField.returnKeyType = UIReturnKeyDone;
    _markField.delegate = self;
    _markField.text = _entry.mark;
    [_card addSubview:_markField];
    y += kRowHeight;

    // 确认按钮
    UIButton *confirm = [UIButton buttonWithType:UIButtonTypeCustom];
    confirm.frame = CGRectMake(kPadding, y + 14, width - kPadding * 2, 47);
    [confirm setTitle:KKLocalized(@"确认记账") forState:UIControlStateNormal];
    [confirm setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    confirm.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    confirm.backgroundColor = kColor_Main_Color;
    confirm.layer.cornerRadius = 8;
    [confirm addTarget:self action:@selector(confirmAction) forControlEvents:UIControlEventTouchUpInside];
    [_card addSubview:confirm];
    y = confirm.bottom + 12;

    _card.frame = CGRectMake(0, self.height - y - SafeAreaBottomHeight, self.width, y + SafeAreaBottomHeight);

    // 键盘弹起时把卡片顶上去，别挡住输入框
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:)
                                                 name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (UILabel *)fieldLabel:(NSString *)text y:(CGFloat)y {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kPadding, y, 60, kRowHeight)];
    label.text = text;
    label.font = [UIFont systemFontOfSize:15];
    label.textColor = kColor_Text_Gary;
    return label;
}

- (CGFloat)addSeparatorAt:(CGFloat)y {
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(kPadding, y, self.width - kPadding * 2, 0.5)];
    line.backgroundColor = kColor_Line_Color;
    [_card addSubview:line];
    return y + 0.5;
}

- (void)buildChips {
    // 支出/收入同名类别（红包/礼金），收入版加「(收)」后缀区分
    NSMutableSet *payNames = [NSMutableSet set];
    for (BKCModel *model in _categories) {
        if (!model.is_income && model.name.length) [payNames addObject:model.name];
    }
    NSMutableArray *chips = [NSMutableArray array];
    CGFloat x = 0;
    for (NSInteger i = 0; i < (NSInteger)_categories.count; i++) {
        BKCModel *model = _categories[i];
        UIButton *chip = [UIButton buttonWithType:UIButtonTypeCustom];
        NSString *name = model.name ?: @"";
        if (model.is_income && [payNames containsObject:name]) {
            name = [name stringByAppendingString:KKLocalized(@"(收)")];
        }
        [chip setTitle:name forState:UIControlStateNormal];
        chip.titleLabel.font = [UIFont systemFontOfSize:13];
        chip.tag = i;
        CGFloat w = [name sizeWithAttributes:@{NSFontAttributeName: chip.titleLabel.font}].width + 26;
        chip.frame = CGRectMake(x, 0, w, 32);
        chip.layer.cornerRadius = 16;
        [chip addTarget:self action:@selector(chipAction:) forControlEvents:UIControlEventTouchUpInside];
        [self styleChip:chip selected:(i == _selectedIndex)];
        [_chipScroll addSubview:chip];
        [chips addObject:chip];
        x = chip.right + 10;
    }
    _chips = chips;
    _chipScroll.contentSize = CGSizeMake(x, 32);
    // 让选中的 chip 一开始就在可视区
    UIButton *selected = _selectedIndex < (NSInteger)chips.count ? chips[_selectedIndex] : nil;
    if (selected) [_chipScroll scrollRectToVisible:CGRectInset(selected.frame, -30, 0) animated:NO];
}

- (void)styleChip:(UIButton *)chip selected:(BOOL)selected {
    chip.backgroundColor = selected ? kColor_Main_Color : kColor_Line_Color;
    [chip setTitleColor:selected ? [UIColor whiteColor] : kColor_Text_Black forState:UIControlStateNormal];
}

#pragma mark - event

- (void)reloadDateBtn {
    NSString *title = nil;
    if ([_selectedDate isToday]) {
        title = KKLocalized(@"今天");
    } else {
        NSDate *yesterday = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay
                                                                     value:-1
                                                                    toDate:[NSDate date]
                                                                   options:0];
        if (yesterday && [_selectedDate isSameDay:yesterday]) {
            title = KKLocalized(@"昨天");
        } else {
            title = [NSString stringWithFormat:@"%ld-%02ld-%02ld",
                     (long)_selectedDate.year, (long)_selectedDate.month, (long)_selectedDate.day];
        }
    }
    [_dateBtn setTitle:[NSString stringWithFormat:@"%@  ▾", title] forState:UIControlStateNormal];
}

- (void)dateBtnClick {
    [self endEditing:YES];
    NSDate *now = [NSDate date];
    BRDatePickerView *picker = [[BRDatePickerView alloc] init];
    BRPickerStyle *style = [[BRPickerStyle alloc] init];
    style.cancelBtnTitle = KKLocalized(@"取消");
    style.doneBtnTitle = KKLocalized(@"确定");
    picker.pickerStyle = style;
    picker.pickerMode = BRDatePickerModeYMD;
    picker.title = KKLocalized(@"选择日期");
    picker.selectDate = _selectedDate;
    picker.minDate = [NSDate br_setYear:2000 month:1 day:1];
    picker.maxDate = [NSDate br_setYear:now.year + 3 month:12 day:31];
    picker.isAutoSelect = NO;
    @weakify(self)
    picker.resultBlock = ^(NSDate *selectDate, NSString *selectValue) {
        @strongify(self)
        if (!selectDate) return;
        self.selectedDate = selectDate;
        [self reloadDateBtn];
    };
    [picker show];
}

- (void)chipAction:(UIButton *)chip {
    if (chip.tag == _selectedIndex) return;
    [self styleChip:_chips[_selectedIndex] selected:NO];
    _selectedIndex = chip.tag;
    [self styleChip:chip selected:YES];
}

- (void)confirmAction {
    [self endEditing:YES];
    double price = [[_amountField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] doubleValue];
    if (price <= 0 || price > 99999999) {
        [self shakeAmountField];
        return;
    }
    BKCModel *category = _categories[_selectedIndex];
    NSDateComponents *comp = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:_selectedDate];

    BookDetailModel *model = [[BookDetailModel alloc] init];
    model.bookId = [[BookDetailModel getBookId] integerValue];   // 临时负数 id，同步成功后换服务端 id
    model.categoryId = category.Id;
    model.price = round(price * 100) / 100.0;
    model.year = comp.year;
    model.month = comp.month;
    model.day = comp.day;
    NSString *mark = [_markField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    model.mark = mark.length ? mark : (category.name ?: @"");

    void (^block)(BookDetailModel *) = self.confirmBlock;
    [self dismissWithCompletion:^{
        if (block) block(model);
    }];
}

- (void)shakeAmountField {
    CABasicAnimation *shake = [CABasicAnimation animationWithKeyPath:@"position.x"];
    shake.duration = 0.06;
    shake.repeatCount = 3;
    shake.autoreverses = YES;
    shake.fromValue = @(_amountField.center.x - 6);
    shake.toValue = @(_amountField.center.x + 6);
    [_amountField.layer addAnimation:shake forKey:@"shake"];
    if (_amountField.text.length == 0) [_amountField becomeFirstResponder];
}

#pragma mark - 键盘

- (void)keyboardWillChange:(NSNotification *)note {
    CGRect endFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGFloat overlap = MAX(0, self.height - endFrame.origin.y);
    [UIView animateWithDuration:MAX(duration, 0.2) animations:^{
        self.card.transform = overlap > 0 ? CGAffineTransformMakeTranslation(0, -(overlap - SafeAreaBottomHeight + 8)) : CGAffineTransformIdentity;
    }];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - 弹出/关闭

- (void)present {
    _dimView.alpha = 0;
    _card.transform = CGAffineTransformMakeTranslation(0, _card.height);
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.dimView.alpha = 1;
        self.card.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)dismiss {
    [self dismissWithCompletion:nil];
}

- (void)dismissWithCompletion:(void (^)(void))completion {
    [self endEditing:YES];
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.dimView.alpha = 0;
        self.card.transform = CGAffineTransformMakeTranslation(0, self.card.height);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        if (completion) completion();
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
