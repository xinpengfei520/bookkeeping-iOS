/**
 * 今日汇率
 * 说明见 RateController.h
 */

#import "RateController.h"
#import <Masonry/Masonry.h>

#pragma mark - Cell（只在本页用，代码创建，不建 XIB）
@interface RateCell : UITableViewCell

@property (nonatomic, strong) UILabel *nameLab;     // 美元 $USD
@property (nonatomic, strong) UILabel *subLab;      // 1 CNY ≈ $0.148090
@property (nonatomic, strong) UILabel *valueLab;    // ¥6.752650

@end

@implementation RateCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

- (void)buildSubviews {
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    _nameLab = [[UILabel alloc] init];
    _nameLab.font = [UIFont systemFontOfSize:AdjustFont(14)];
    _nameLab.textColor = kColor_Text_Black;
    [self.contentView addSubview:_nameLab];

    _subLab = [[UILabel alloc] init];
    _subLab.font = [UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight];
    _subLab.textColor = kColor_Text_Gary;
    [self.contentView addSubview:_subLab];

    _valueLab = [[UILabel alloc] init];
    _valueLab.font = [UIFont systemFontOfSize:AdjustFont(15) weight:UIFontWeightMedium];
    _valueLab.textColor = kColor_Main_Color;
    _valueLab.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:_valueLab];

    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(countcoordinatesX(15));
        make.top.equalTo(self.contentView).offset(countcoordinatesX(12));
    }];
    [_subLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_nameLab);
        make.top.equalTo(self->_nameLab.mas_bottom).offset(4);
    }];
    [_valueLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-countcoordinatesX(15));
        make.centerY.equalTo(self.contentView);
        make.left.greaterThanOrEqualTo(self->_nameLab.mas_right).offset(10);
    }];
}

@end


#pragma mark - 声明
@interface RateController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) UILabel *footerLab;
@property (nonatomic, copy  ) NSArray<NSString *> *codes;                    // 展示的外币列表
@property (nonatomic, copy  ) NSDictionary<NSString *, NSNumber *> *rates;   // 1 外币 = N 人民币
@property (nonatomic, copy  ) NSString *effectiveDate;
@property (nonatomic, copy  ) NSString *source;
@property (nonatomic, copy  ) NSString *errorMsg;
@property (nonatomic, assign) BOOL stale;
@property (nonatomic, assign) BOOL loaded;

@end


#pragma mark - 实现
@implementation RateController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = KKLocalized(@"今日汇率");
    self.view.backgroundColor = kColor_BG;

    [self.view addSubview:self.table];
    [self.table mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self showProgressHUD];
    [self getRatesRequest];
}


#pragma mark - request
// 与记账页用的是同一个接口，保证这里看到的数字就是记一笔外币时会用到的数字。
// 服务端已按天缓存（最新 6 小时），APP 不做本地缓存。
- (void)getRatesRequest {
    @weakify(self)
    [AFNManager GET:bookRatesRequest params:nil complete:^(APPResult *result) {
        @strongify(self)
        [self hideHUD];
        [self.table.refreshControl endRefreshing];
        self.loaded = YES;

        if (result.status != HttpStatusSuccess || result.code != BIZ_SUCCESS) {
            self.errorMsg = result.msg.length ? result.msg : KKLocalized(@"汇率获取失败，请稍后重试");
            [self reload];
            [self showTextHUD:self.errorMsg delay:1.5f];
            return;
        }

        NSDictionary *rates = [KKCurrency ratesFromResponseData:result.data];
        if (rates == nil) {
            self.errorMsg = KKLocalized(@"汇率获取失败，请稍后重试");
            [self reload];
            [self showTextHUD:self.errorMsg delay:1.5f];
            return;
        }

        NSDictionary *data = result.data;
        self.errorMsg = nil;
        self.rates = rates;
        self.stale = [KKCurrency staleFromResponseData:data];
        self.effectiveDate = [data[@"effectiveDate"] isKindOfClass:[NSString class]] ? data[@"effectiveDate"] : nil;
        self.source = [data[@"source"] isKindOfClass:[NSString class]] ? data[@"source"] : nil;
        [self reload];
    }];
}

- (void)refreshControlChanged {
    [self getRatesRequest];
}

- (void)reload {
    [self.table reloadData];
    // footer 是自适应高度的，内容变了要让 table 重新问一次高度
    [self.table beginUpdates];
    [self.table endUpdates];
}


#pragma mark - 文案
// 表尾：生效日 + 数据源 + 缓存说明。stale 时把"可能不是最新"标红排在最前面。
- (NSAttributedString *)footerText {
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
    NSDictionary *warnAttrs = @{
        NSFontAttributeName: [UIFont systemFontOfSize:AdjustFont(11)],
        NSForegroundColorAttributeName: kColor_Text_Red,
    };
    NSDictionary *normalAttrs = @{
        NSFontAttributeName: [UIFont systemFontOfSize:AdjustFont(11) weight:UIFontWeightLight],
        NSForegroundColorAttributeName: kColor_Text_Gary,
    };

    if (self.errorMsg.length) {
        [text appendAttributedString:[[NSAttributedString alloc] initWithString:self.errorMsg attributes:warnAttrs]];
        [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:normalAttrs]];
    }
    if (self.stale) {
        [text appendAttributedString:[[NSAttributedString alloc] initWithString:KKLocalized(@"当前汇率可能不是最新（上游数据源暂时不可达，显示的是缓存值）") attributes:warnAttrs]];
        [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:normalAttrs]];
    }
    if (self.effectiveDate.length) {
        // 数据源（欧洲央行）周末 / 节假日不发布，会自动回退到最近一个工作日，
        // 所以生效日可能不是今天，这是正常的。
        NSMutableString *line = [NSMutableString stringWithFormat:KKLocalized(@"汇率生效日：%@"), self.effectiveDate];
        if (self.source.length) {
            [line appendFormat:KKLocalized(@" · 数据源：%@"), self.source];
        }
        [line appendString:@"\n"];
        [text appendAttributedString:[[NSAttributedString alloc] initWithString:line attributes:normalAttrs]];
    }
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:KKLocalized(@"汇率由服务端统一提供，记一笔外币时用的是同一份数据。") attributes:normalAttrs]];
    return text;
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.codes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"RateCell";
    RateCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[RateCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }

    NSString *code = self.codes[indexPath.row];
    CGFloat rate = [self.rates[code] doubleValue];
    cell.nameLab.text = [NSString stringWithFormat:@"%@ %@", [KKCurrency nameForCode:code], [KKCurrency badgeForCode:code]];
    if (rate > 0) {
        cell.valueLab.text = [NSString stringWithFormat:@"¥%@", [KKCurrency formatRate:rate]];
        // 反向报价只作参考，记账一律用正向的「1 外币 = N 人民币」
        cell.subLab.text = [NSString stringWithFormat:KKLocalized(@"1 CNY ≈ %@%.6f"),
                            [KKCurrency symbolForCode:code], 1.0 / rate];
    } else {
        cell.valueLab.text = @"--";
        cell.subLab.text = self.loaded ? KKLocalized(@"暂无汇率") : KKLocalized(@"汇率获取中…");
    }
    return cell;
}


#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return countcoordinatesX(60);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return countcoordinatesX(36);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = kColor_BG;
    UILabel *lab = [[UILabel alloc] init];
    lab.font = [UIFont systemFontOfSize:AdjustFont(11) weight:UIFontWeightLight];
    lab.textColor = kColor_Text_Gary;
    lab.text = KKLocalized(@"1 单位外币可兑换的人民币");
    [view addSubview:lab];
    [lab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(view).offset(countcoordinatesX(15));
        make.bottom.equalTo(view).offset(-6);
    }];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    CGFloat width = SCREEN_WIDTH - countcoordinatesX(30);
    CGSize size = [self.footerText boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                                context:nil].size;
    return ceil(size.height) + countcoordinatesX(20);
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = kColor_BG;
    self.footerLab.attributedText = [self footerText];
    [view addSubview:self.footerLab];
    [self.footerLab mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(view).offset(countcoordinatesX(15));
        make.right.equalTo(view).offset(-countcoordinatesX(15));
        make.top.equalTo(view).offset(countcoordinatesX(10));
    }];
    return view;
}


#pragma mark - get
- (UITableView *)table {
    if (!_table) {
        _table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _table.delegate = self;
        _table.dataSource = self;
        _table.backgroundColor = kColor_BG;
        _table.showsVerticalScrollIndicator = NO;
        _table.separatorInset = UIEdgeInsetsMake(0, countcoordinatesX(15), 0, 0);
        _table.separatorColor = kColor_Line_Color;
        _table.refreshControl = ({
            UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
            refresh.tintColor = kColor_Main_Color;
            [refresh addTarget:self action:@selector(refreshControlChanged) forControlEvents:UIControlEventValueChanged];
            refresh;
        });
    }
    return _table;
}

- (UILabel *)footerLab {
    if (!_footerLab) {
        _footerLab = [[UILabel alloc] init];
        _footerLab.numberOfLines = 0;
    }
    return _footerLab;
}

- (NSArray<NSString *> *)codes {
    if (!_codes) {
        // 只展示外币；人民币是基准，没有"对自己的汇率"
        NSMutableArray *arrm = [NSMutableArray array];
        for (NSString *code in [KKCurrency supportedCodes]) {
            if ([KKCurrency isForeignCode:code]) {
                [arrm addObject:code];
            }
        }
        _codes = arrm;
    }
    return _codes;
}

@end
