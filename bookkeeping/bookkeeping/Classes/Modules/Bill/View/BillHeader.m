/**
 * 头视图 (code-only — converted from BillHeader.xib)
 * @author 郑业强 2019-01-09 创建文件
 */

#import "BillHeader.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface BillHeader()

// 上半部绿色卡片
@property (nonatomic, strong) UIView *content;
// 卡片内：标题 "结余" + 大金额 money1Lab + 两块小金额（收入 money2Lab + 支出 money3Lab）
@property (nonatomic, strong) UILabel *lab1;        // "结余"
@property (nonatomic, strong) UILabel *money1Lab;   // 30pt 结余金额
@property (nonatomic, strong) UIView *line1;        // 收入/支出之间垂直分隔线（红）
@property (nonatomic, strong) UILabel *lab2;        // "收入"
@property (nonatomic, strong) UILabel *money2Lab;   // 14pt 收入金额
@property (nonatomic, strong) UILabel *lab3;        // "支出"
@property (nonatomic, strong) UILabel *money3Lab;   // 14pt 支出金额
@property (nonatomic, strong) UIView *leftHalfLine; // 卡片底部左半透明线（sug-1N-y39，定位锚）
@property (nonatomic, strong) UIView *rightHalfLine;// 卡片底部右半透明线（fAE-HX-9tW，定位锚）

// 下半部 4 列 column header（月份 / 收入 / 支出 / 结余）+ 底部 hairline
@property (nonatomic, strong) UILabel *colMonth;
@property (nonatomic, strong) UILabel *colIncome;
@property (nonatomic, strong) UILabel *colPay;
@property (nonatomic, strong) UILabel *colBalance;
@property (nonatomic, strong) UIView *line;         // 整体底部 hairline

@end


#pragma mark - 实现
@implementation BillHeader

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
        [self initUI];
    }
    return self;
}

- (void)buildSubviews {
    // 整体视图背景白，content card 高度 = self.height - 30 (留给 column header 区)
    self.backgroundColor = [UIColor systemBackgroundColor];

    // ====== 上半部 content 卡片 ======
    _content = [[UIView alloc] init];
    [self addSubview:_content];

    _lab1 = [[UILabel alloc] init];
    _lab1.textAlignment = NSTextAlignmentCenter;
    [_content addSubview:_lab1];

    _money1Lab = [[UILabel alloc] init];
    _money1Lab.textAlignment = NSTextAlignmentCenter;
    [_content addSubview:_money1Lab];

    _line1 = [[UIView alloc] init];
    [_content addSubview:_line1];

    // sug-1N-y39 / fAE-HX-9tW 在 XIB 里是底部 1pt 线 + 用来做 money2/3Lab centerX 的锚点；
    // 这里转码后只作为不可见的"占位框"，给 money2/3Lab 的左右居中提供参照。
    _leftHalfLine = [[UIView alloc] init];
    [_content addSubview:_leftHalfLine];

    _rightHalfLine = [[UIView alloc] init];
    [_content addSubview:_rightHalfLine];

    _lab2 = [[UILabel alloc] init];
    [_content addSubview:_lab2];

    _money2Lab = [[UILabel alloc] init];
    [_content addSubview:_money2Lab];

    _lab3 = [[UILabel alloc] init];
    [_content addSubview:_lab3];

    _money3Lab = [[UILabel alloc] init];
    [_content addSubview:_money3Lab];

    // ====== 下半部 column header ======
    _colMonth = [[UILabel alloc] init];
    [self addSubview:_colMonth];

    _colIncome = [[UILabel alloc] init];
    [self addSubview:_colIncome];

    _colPay = [[UILabel alloc] init];
    [self addSubview:_colPay];

    _colBalance = [[UILabel alloc] init];
    [self addSubview:_colBalance];

    _line = [[UIView alloc] init];
    [self addSubview:_line];

    // ====== content 卡片定位：top/left/right 贴边，bottom 与 column header 顶对齐 ======
    [_content mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
        make.bottom.equalTo(self->_colMonth.mas_top);
    }];

    // content 内部
    [_lab1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self->_content);
    }];
    [_money1Lab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self->_lab1.mas_bottom).offset(5);
        make.left.right.equalTo(self->_content);
    }];
    [_line1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self->_content);
        make.top.equalTo(self->_money1Lab.mas_bottom).offset(10);
        make.width.equalTo(@0.5);
        make.height.equalTo(@20);
    }];
    // 卡片底部两条占位锚（不可见，做 money2/3Lab 的水平居中锚点）
    [_leftHalfLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.equalTo(self->_content);
        make.right.equalTo(self->_line1.mas_left);
        make.height.equalTo(@1);
    }];
    [_rightHalfLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_line1.mas_right);
        make.right.bottom.equalTo(self->_content);
        make.height.equalTo(@1);
    }];
    // money2Lab + lab2 ("收入")：水平上 lab2 在 money2 左边 5pt，整体居中在 leftHalfLine
    // centerX - 20（XIB: RBd-W6-Fpt）→ 但同时 money2.centerY 在 line1.centerY（RVh-Wc-ZNJ）
    [_money2Lab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self->_leftHalfLine).offset(20);
        make.centerY.equalTo(self->_line1);
    }];
    [_lab2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self->_money2Lab.mas_left).offset(-5);
        make.bottom.equalTo(self->_money2Lab.mas_bottom).offset(-2);
    }];
    // money3Lab + lab3 ("支出")：lab3 在 money3 左边 5pt，整体居中在 rightHalfLine
    // centerX + 20（XIB: yaV-9P-HWp）
    [_money3Lab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self->_rightHalfLine).offset(20);
        make.centerY.equalTo(self->_line1);
    }];
    [_lab3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self->_money3Lab.mas_left).offset(-5);
        make.bottom.equalTo(self->_money3Lab.mas_bottom).offset(-2);
    }];

    // ====== 下半部：4 个等宽 column header label，月份 leading=20，结余 trailing=0 ======
    [_colMonth mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(countcoordinatesX(20));
        make.bottom.equalTo(self->_line.mas_top);
        make.height.equalTo(@30);
    }];
    [_colIncome mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_colMonth.mas_right);
        make.top.bottom.equalTo(self->_colMonth);
        make.width.equalTo(self->_colMonth);
    }];
    [_colPay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_colIncome.mas_right);
        make.top.bottom.equalTo(self->_colMonth);
        make.width.equalTo(self->_colMonth);
    }];
    [_colBalance mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_colPay.mas_right);
        make.right.equalTo(self);
        make.top.bottom.equalTo(self->_colMonth);
        make.width.equalTo(self->_colMonth);
    }];

    // ====== 底部 hairline ======
    [_line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.height.equalTo(@0.5);
    }];
}

- (void)initUI {
    [self.content setBackgroundColor:kColor_Main_Color];
    // line / line1 — XIB 里 line1 是定写红色，line 是 sRGB 烤死的 groupTableViewBackgroundColor；
    // 这里 line 走 kColor_Line_Color（dark 模式 #2C2C2E），line1 维持半透明白
    [self.line setBackgroundColor:kColor_Line_Color];
    [self.line1 setBackgroundColor:[kColor_Text_White colorWithAlphaComponent:0.5]];

    // content 卡片内文字本地化 + 白色
    [self.lab1 setText:KKLocalized(@"结余")];
    [self.lab2 setText:KKLocalized(@"收入")];
    [self.lab3 setText:KKLocalized(@"支出")];

    [self.lab1 setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.lab1 setTextColor:kColor_Text_White];
    [self.lab2 setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.lab2 setTextColor:kColor_Text_White];
    [self.lab3 setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.lab3 setTextColor:kColor_Text_White];

    [self.money1Lab setFont:[UIFont systemFontOfSize:AdjustFont(30) weight:UIFontWeightLight]];
    [self.money1Lab setTextColor:kColor_Text_White];
    [self.money2Lab setFont:[UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight]];
    [self.money2Lab setTextColor:kColor_Text_White];
    [self.money3Lab setFont:[UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight]];
    [self.money3Lab setTextColor:kColor_Text_White];

    // column header：原 XIB 里 4 个 label 是 XIB-baked 中文（月份/收入/支出/结余）+ 没绑 outlet，
    // 之前的 i18n 改 XIB 才能 localize。这次转代码顺手做掉。
    UIFont *colFont = [UIFont systemFontOfSize:AdjustFont(10)];
    NSArray<UILabel *> *cols = @[self.colMonth, self.colIncome, self.colPay, self.colBalance];
    NSArray<NSString *> *names = @[KKLocalized(@"月份"), KKLocalized(@"收入"), KKLocalized(@"支出"), KKLocalized(@"结余")];
    for (NSUInteger i = 0; i < cols.count; i++) {
        cols[i].text = names[i];
        cols[i].font = colFont;
        cols[i].textColor = kColor_Text_Gary;
    }
}


#pragma mark - set
- (void)setIncome:(CGFloat)income {
    _income = income;
    NSString *incomeStr = [NSString stringWithFormat:@"%.2f", income];
    [self.money2Lab setAttributedText:[NSAttributedString createMath:incomeStr integer:[UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight] decimal:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight] color:kColor_Text_White]];

    NSString *money = [NSString stringWithFormat:@"%.2f", income - _pay];
    [self.money1Lab setAttributedText:[NSAttributedString createMath:money integer:[UIFont systemFontOfSize:AdjustFont(30) weight:UIFontWeightLight] decimal:[UIFont systemFontOfSize:AdjustFont(26) weight:UIFontWeightLight] color:kColor_Text_White]];
}

- (void)setPay:(CGFloat)pay {
    _pay = pay;
    NSString *payStr = [NSString stringWithFormat:@"%.2f", pay];
    [self.money3Lab setAttributedText:[NSAttributedString createMath:payStr integer:[UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight] decimal:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight] color:kColor_Text_White]];

    NSString *money = [NSString stringWithFormat:@"%.2f", _income - pay];
    [self.money1Lab setAttributedText:[NSAttributedString createMath:money integer:[UIFont systemFontOfSize:AdjustFont(30) weight:UIFontWeightLight] decimal:[UIFont systemFontOfSize:AdjustFont(26) weight:UIFontWeightLight] color:kColor_Text_White]];
}



@end
