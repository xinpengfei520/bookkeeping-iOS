//
//  OCRConfirmView.m
//  bookkeeping
//

#import "OCRConfirmView.h"
#import "KKBookTextParser.h"
#import "VoiceConfirmView.h"
#import "BKCIncomeModel.h"
#import "BookDetailModel.h"

static const CGFloat kPadding = 20;
static const CGFloat kRowHeight = 64;

#pragma mark - 行

@interface OCRConfirmCell : UITableViewCell
@property (nonatomic, strong) UILabel *markLabel;
@property (nonatomic, strong) UILabel *metaLabel;
@property (nonatomic, strong) UILabel *priceLabel;
- (void)bindEntry:(KKParsedBookEntry *)entry categories:(NSArray<BKCModel *> *)categories;
@end

@implementation OCRConfirmCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _markLabel = [[UILabel alloc] init];
        _markLabel.font = [UIFont systemFontOfSize:16];
        _markLabel.textColor = kColor_Text_Black;
        [self.contentView addSubview:_markLabel];
        _metaLabel = [[UILabel alloc] init];
        _metaLabel.font = [UIFont systemFontOfSize:12];
        _metaLabel.textColor = kColor_Text_Gary;
        [self.contentView addSubview:_metaLabel];
        _priceLabel = [[UILabel alloc] init];
        _priceLabel.font = [UIFont boldSystemFontOfSize:18];
        _priceLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:_priceLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width;
    CGFloat h = self.contentView.bounds.size.height;
    _priceLabel.frame = CGRectMake(w - 120, 0, 108, h);
    _markLabel.frame = CGRectMake(kPadding, 10, w - 140, 24);
    _metaLabel.frame = CGRectMake(kPadding, 34, w - 140, 18);
}

- (void)bindEntry:(KKParsedBookEntry *)entry categories:(NSArray<BKCModel *> *)categories {
    NSString *mark = entry.mark.length ? entry.mark : KKLocalized(@"未识别备注");
    _markLabel.text = mark;
    BKCModel *cat = nil;
    for (BKCModel *m in categories) {
        if (m.Id == entry.categoryId) { cat = m; break; }
    }
    NSString *catName = cat.name.length ? cat.name : KKLocalized(@"未选类别");
    _metaLabel.text = [NSString stringWithFormat:@"%@  ·  %ld-%02ld-%02ld",
                       catName, (long)entry.year, (long)entry.month, (long)entry.day];
    if (entry.price > 0) {
        _priceLabel.text = [NSString stringWithFormat:@"%.2f", entry.price];
        _priceLabel.textColor = kColor_Text_Black;
    } else {
        _priceLabel.text = KKLocalized(@"待补金额");
        _priceLabel.textColor = kColor_Text_Red;
    }
}

@end


#pragma mark - 卡片

@interface OCRConfirmView () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray<KKParsedBookEntry *> *entries;
@property (nonatomic, strong) NSArray<BKCModel *> *categories;
@property (nonatomic, copy  ) void (^confirmBlock)(NSArray<BookDetailModel *> *models);
@property (nonatomic, strong) UIView *dimView;
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) UIButton *confirmBtn;
@property (nonatomic, strong) UILabel *subtitle;

@end

@implementation OCRConfirmView

+ (void)showWithEntries:(NSArray<KKParsedBookEntry *> *)entries
             categories:(NSArray<BKCModel *> *)categories
                confirm:(void (^)(NSArray<BookDetailModel *> *))confirm {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window || categories.count == 0) return;

    NSArray<KKParsedBookEntry *> *list = entries.count ? entries : @[[self blankEntry]];
    if (list.count == 1) {
        [VoiceConfirmView showWithEntry:list.firstObject categories:categories confirm:^(BookDetailModel *model) {
            if (confirm) confirm(@[model]);
        }];
        return;
    }

    OCRConfirmView *view = [[OCRConfirmView alloc] initWithFrame:window.bounds];
    view.entries = [list mutableCopy];
    view.categories = categories;
    view.confirmBlock = confirm;
    [view buildSubviews];
    [window addSubview:view];
    [view present];
}

+ (KKParsedBookEntry *)blankEntry {
    KKParsedBookEntry *e = [[KKParsedBookEntry alloc] init];
    e.categoryId = -1;
    NSDate *now = [NSDate date];
    e.year = now.year;
    e.month = now.month;
    e.day = now.day;
    e.rawText = @"";
    e.mark = @"";
    return e;
}

#pragma mark - build

- (void)buildSubviews {
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
    y = title.bottom + 4;

    _subtitle = [[UILabel alloc] initWithFrame:CGRectMake(kPadding, y, width - kPadding * 2, 18)];
    _subtitle.font = [UIFont systemFontOfSize:12];
    _subtitle.textColor = kColor_Text_Gary;
    _subtitle.textAlignment = NSTextAlignmentCenter;
    [_card addSubview:_subtitle];
    y = _subtitle.bottom + 8;

    CGFloat tableH = MIN(kRowHeight * _entries.count, self.height * 0.42);
    _table = [[UITableView alloc] initWithFrame:CGRectMake(0, y, width, tableH) style:UITableViewStylePlain];
    _table.delegate = self;
    _table.dataSource = self;
    _table.rowHeight = kRowHeight;
    _table.separatorInset = UIEdgeInsetsMake(0, kPadding, 0, kPadding);
    _table.backgroundColor = [UIColor clearColor];
    _table.tableFooterView = [UIView new];
    [_table registerClass:[OCRConfirmCell class] forCellReuseIdentifier:@"OCRConfirmCell"];
    [_card addSubview:_table];
    y = _table.bottom + 12;

    _confirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _confirmBtn.frame = CGRectMake(kPadding, y, width - kPadding * 2, 47);
    [_confirmBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _confirmBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    _confirmBtn.backgroundColor = kColor_Main_Color;
    _confirmBtn.layer.cornerRadius = 8;
    [_confirmBtn addTarget:self action:@selector(confirmAction) forControlEvents:UIControlEventTouchUpInside];
    [_card addSubview:_confirmBtn];
    y = _confirmBtn.bottom + 12;

    _card.frame = CGRectMake(0, self.height - y - SafeAreaBottomHeight, self.width, y + SafeAreaBottomHeight);
    [self reloadChrome];
}

- (void)reloadChrome {
    _subtitle.text = [NSString stringWithFormat:KKLocalized(@"识别到 %ld 笔，点按可改，左滑删除"), (long)_entries.count];
    NSString *title = _entries.count > 1
        ? [NSString stringWithFormat:KKLocalized(@"确认记账 %ld 笔"), (long)_entries.count]
        : KKLocalized(@"确认记账");
    [_confirmBtn setTitle:title forState:UIControlStateNormal];
}

#pragma mark - table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _entries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OCRConfirmCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OCRConfirmCell" forIndexPath:indexPath];
    [cell bindEntry:_entries[indexPath.row] categories:_categories];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    KKParsedBookEntry *entry = _entries[indexPath.row];
    @weakify(self)
    [VoiceConfirmView showWithEntry:entry categories:_categories confirm:^(BookDetailModel *model) {
        @strongify(self)
        if (!self) return;
        entry.price = model.price;
        entry.categoryId = model.categoryId;
        entry.year = model.year;
        entry.month = model.month;
        entry.day = model.day;
        entry.mark = model.mark;
        [self.table reloadData];
    }];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return KKLocalized(@"删除");
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) return;
    [_entries removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    if (_entries.count == 0) {
        [self dismiss];
        return;
    }
    [self reloadChrome];
}

#pragma mark - confirm

- (BookDetailModel *)modelFromEntry:(KKParsedBookEntry *)entry {
    BKCModel *category = nil;
    for (BKCModel *m in _categories) {
        if (m.Id == entry.categoryId) { category = m; break; }
    }
    if (!category) {
        for (BKCModel *m in _categories) {
            if (!m.is_income) { category = m; break; }
        }
        category = category ?: _categories.firstObject;
    }
    BookDetailModel *model = [[BookDetailModel alloc] init];
    model.bookId = [[BookDetailModel getBookId] integerValue];
    model.categoryId = category.Id;
    model.price = round(entry.price * 100) / 100.0;
    model.year = entry.year;
    model.month = entry.month;
    model.day = entry.day;
    NSString *mark = [entry.mark stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    model.mark = mark.length ? mark : (category.name ?: @"");
    return model;
}

- (void)confirmAction {
    for (NSInteger i = 0; i < (NSInteger)_entries.count; i++) {
        if (_entries[i].price <= 0 || _entries[i].price > 99999999) {
            NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
            [_table scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
            UITableViewCell *cell = [_table cellForRowAtIndexPath:path];
            CABasicAnimation *shake = [CABasicAnimation animationWithKeyPath:@"position.x"];
            shake.duration = 0.06;
            shake.repeatCount = 3;
            shake.autoreverses = YES;
            shake.fromValue = @(cell.center.x - 6);
            shake.toValue = @(cell.center.x + 6);
            [cell.layer addAnimation:shake forKey:@"shake"];
            return;
        }
    }
    NSMutableArray *models = [NSMutableArray arrayWithCapacity:_entries.count];
    for (KKParsedBookEntry *e in _entries) {
        [models addObject:[self modelFromEntry:e]];
    }
    void (^block)(NSArray *) = self.confirmBlock;
    [self dismissWithCompletion:^{
        if (block) block(models);
    }];
}

#pragma mark - present / dismiss

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
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.dimView.alpha = 0;
        self.card.transform = CGAffineTransformMakeTranslation(0, self.card.height);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        if (completion) completion();
    }];
}

@end
