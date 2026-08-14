//
//  KKLLMParserTests.m
//  bookkeepingTests
//
//  联调验证：测试 KKLLMParser 对 /book/parse 后端响应的字段合并逻辑。
//  不依赖网络，直接调用 mergeData:intoEntry:categories: 验证契约。
//
//  覆盖场景：
//    · needsLLMForEntry — 触发 LLM 的判断条件
//    · price — 仅补全、上限校验、取整
//    · categoryName — 精确匹配、前缀匹配、收入方向、不覆盖已有值
//    · isIncome 兜底 — 类别未命中时仍采纳方向
//    · mark — 仅补全、不覆盖、超长截断
//    · date — 刻意不合并（客户端已由规则解析器处理）
//

#import <XCTest/XCTest.h>

// ===== 重声明：测试 target 不走主 target PCH，按需声明接口 =====

@interface KKParsedBookEntry : NSObject
@property (nonatomic, assign) double     price;
@property (nonatomic, assign) NSInteger  categoryId;
@property (nonatomic, assign) BOOL       isIncome;
@property (nonatomic, assign) NSInteger  year, month, day;
@property (nonatomic, copy  ) NSString  *mark;
@property (nonatomic, copy  ) NSString  *rawText;
@end

@interface BKCModel : NSObject
@property (nonatomic, assign) NSInteger  Id;
@property (nonatomic, copy  ) NSString  *name;
@property (nonatomic, assign) BOOL       is_income;
@end

@interface KKLLMParser : NSObject
+ (BOOL)needsLLMForEntry:(KKParsedBookEntry *)entry;
// 测试白盒访问私有方法（ObjC 运行时可直接 dispatch，和主 target 共享同一实现）
+ (void)mergeData:(NSDictionary *)data
        intoEntry:(KKParsedBookEntry *)entry
       categories:(NSArray *)categories;
@end

// ===== 辅助 =====

static BKCModel *makeCategory(NSInteger catId, NSString *name, BOOL isIncome) {
    BKCModel *m = [[BKCModel alloc] init];
    m.Id        = catId;
    m.name      = name;
    m.is_income = isIncome;
    return m;
}

static KKParsedBookEntry *blankEntry(void) {
    KKParsedBookEntry *e = [[KKParsedBookEntry alloc] init];
    e.price      = 0;
    e.categoryId = -1;
    e.isIncome   = NO;
    e.year  = 2026; e.month = 8; e.day = 14;
    e.mark  = @"";
    e.rawText = @"";
    return e;
}

// ===== 测试类 =====

@interface KKLLMParserTests : XCTestCase
@property (nonatomic, strong) NSArray *cats; // 精简类别表
@end

@implementation KKLLMParserTests

- (void)setUp {
    self.cats = @[
        makeCategory(1, @"餐饮",  NO),
        makeCategory(2, @"交通",  NO),
        makeCategory(3, @"报销",  YES),
        makeCategory(4, @"工资",  YES),
        makeCategory(5, @"亲友",  NO),
        makeCategory(6, @"红包",  YES),
        makeCategory(7, @"通讯",  NO),
        makeCategory(8, @"信用卡", NO),
        makeCategory(9, @"运动",  NO),
    ];
}

#pragma mark - needsLLMForEntry

- (void)test_needsLLM_priceZero {
    KKParsedBookEntry *e = blankEntry();
    e.price = 0; e.categoryId = 1;
    XCTAssertTrue([KKLLMParser needsLLMForEntry:e]);
}

- (void)test_needsLLM_categoryMinus1 {
    KKParsedBookEntry *e = blankEntry();
    e.price = 35.8; e.categoryId = -1;
    XCTAssertTrue([KKLLMParser needsLLMForEntry:e]);
}

- (void)test_needsLLM_bothPresent_returnsFalse {
    KKParsedBookEntry *e = blankEntry();
    e.price = 35.8; e.categoryId = 1;
    XCTAssertFalse([KKLLMParser needsLLMForEntry:e]);
}

#pragma mark - price

- (void)test_price_mergedWhenZero {
    KKParsedBookEntry *e = blankEntry();
    [KKLLMParser mergeData:@{@"price": @60.0, @"categoryName": @"", @"isIncome": @NO}
                 intoEntry:e categories:self.cats];
    XCTAssertEqualWithAccuracy(e.price, 60.0, 0.001);
}

- (void)test_price_notOverriddenWhenPositive {
    KKParsedBookEntry *e = blankEntry();
    e.price = 35.8;
    [KKLLMParser mergeData:@{@"price": @99.0, @"categoryName": @"", @"isIncome": @NO}
                 intoEntry:e categories:self.cats];
    XCTAssertEqualWithAccuracy(e.price, 35.8, 0.001, @"规则解析已有 price 不应被覆盖");
}

- (void)test_price_negativeIgnored {
    KKParsedBookEntry *e = blankEntry();
    [KKLLMParser mergeData:@{@"price": @(-10.0), @"categoryName": @"", @"isIncome": @NO}
                 intoEntry:e categories:self.cats];
    XCTAssertEqualWithAccuracy(e.price, 0.0, 0.001, @"负数金额不应被采用");
}

- (void)test_price_overCapIgnored {
    KKParsedBookEntry *e = blankEntry();
    [KKLLMParser mergeData:@{@"price": @100000000.0, @"categoryName": @"", @"isIncome": @NO}
                 intoEntry:e categories:self.cats];
    XCTAssertEqualWithAccuracy(e.price, 0.0, 0.001, @"超上限（99999999）金额不应被采用");
}

- (void)test_price_rounded {
    KKParsedBookEntry *e = blankEntry();
    [KKLLMParser mergeData:@{@"price": @(35.8049), @"categoryName": @"", @"isIncome": @NO}
                 intoEntry:e categories:self.cats];
    // round(35.8049 * 100) / 100.0 == 35.80
    XCTAssertEqualWithAccuracy(e.price, 35.80, 0.001);
}

#pragma mark - categoryName

- (void)test_category_exactMatch {
    KKParsedBookEntry *e = blankEntry();
    [KKLLMParser mergeData:@{@"price": @60.0, @"categoryName": @"餐饮", @"isIncome": @NO}
                 intoEntry:e categories:self.cats];
    XCTAssertEqual(e.categoryId, 1);
    XCTAssertFalse(e.isIncome);
}

- (void)test_category_prefixMatch {
    // LLM 返回 "餐饮类" 应前缀匹配到 "餐饮"
    KKParsedBookEntry *e = blankEntry();
    [KKLLMParser mergeData:@{@"price": @60.0, @"categoryName": @"餐饮类", @"isIncome": @NO}
                 intoEntry:e categories:self.cats];
    XCTAssertEqual(e.categoryId, 1, @"前缀匹配应命中「餐饮」");
}

- (void)test_category_incomeDirection {
    KKParsedBookEntry *e = blankEntry();
    [KKLLMParser mergeData:@{@"price": @200.0, @"categoryName": @"报销", @"isIncome": @YES}
                 intoEntry:e categories:self.cats];
    XCTAssertEqual(e.categoryId, 3);
    XCTAssertTrue(e.isIncome, @"报销类别应设 isIncome=YES");
}

- (void)test_category_notOverriddenWhenPresent {
    KKParsedBookEntry *e = blankEntry();
    e.categoryId = 2; // 交通（规则已命中）
    [KKLLMParser mergeData:@{@"price": @60.0, @"categoryName": @"餐饮", @"isIncome": @NO}
                 intoEntry:e categories:self.cats];
    XCTAssertEqual(e.categoryId, 2, @"已有 categoryId 不应被 LLM 覆盖");
}

- (void)test_category_notFound_fallbackIsIncome {
    // 类别名未命中本地表，但 LLM 给出收支方向 → 应采纳方向、保留 categoryId=-1
    KKParsedBookEntry *e = blankEntry();
    e.isIncome = NO;
    [KKLLMParser mergeData:@{@"price": @100.0, @"categoryName": @"未知分类XYZ", @"isIncome": @YES}
                 intoEntry:e categories:self.cats];
    XCTAssertEqual(e.categoryId, -1, @"未命中时 categoryId 保持 -1");
    XCTAssertTrue(e.isIncome, @"未命中时仍应采纳 isIncome 方向");
}

- (void)test_category_emptyName_noChange {
    KKParsedBookEntry *e = blankEntry();
    [KKLLMParser mergeData:@{@"price": @100.0, @"categoryName": @"", @"isIncome": @YES}
                 intoEntry:e categories:self.cats];
    XCTAssertEqual(e.categoryId, -1, @"空 categoryName 不应改变 categoryId");
}

#pragma mark - mark

- (void)test_mark_mergedWhenEmpty {
    KKParsedBookEntry *e = blankEntry();
    [KKLLMParser mergeData:@{@"price": @60.0, @"categoryName": @"", @"isIncome": @NO,
                              @"mark": @"和老王吃饭"}
                 intoEntry:e categories:self.cats];
    XCTAssertEqualObjects(e.mark, @"和老王吃饭");
}

- (void)test_mark_notOverriddenWhenPresent {
    KKParsedBookEntry *e = blankEntry();
    e.mark = @"打车";
    [KKLLMParser mergeData:@{@"price": @35.0, @"categoryName": @"", @"isIncome": @NO,
                              @"mark": @"滴滴出行"}
                 intoEntry:e categories:self.cats];
    XCTAssertEqualObjects(e.mark, @"打车", @"已有备注不应被 LLM 覆盖");
}

- (void)test_mark_truncatedAt20 {
    KKParsedBookEntry *e = blankEntry();
    NSString *longMark = @"这是一段超过二十个字的备注文字用于测试截断行为是否正确";
    [KKLLMParser mergeData:@{@"price": @60.0, @"categoryName": @"", @"isIncome": @NO,
                              @"mark": longMark}
                 intoEntry:e categories:self.cats];
    XCTAssertEqual(e.mark.length, 20u, @"超过 20 字的 mark 应截断");
}

- (void)test_mark_exactlyMax_notTruncated {
    KKParsedBookEntry *e = blankEntry();
    NSString *mark20 = @"恰好二十个字的备注文字内容"; // 12字，≤20
    // 构造恰好 20 字的字符串
    NSString *mark = @"一二三四五六七八九十一二三四五六七八九十";
    XCTAssertEqual(mark.length, 20u);
    [KKLLMParser mergeData:@{@"price": @60.0, @"categoryName": @"", @"isIncome": @NO,
                              @"mark": mark}
                 intoEntry:e categories:self.cats];
    XCTAssertEqual(e.mark.length, 20u);
    (void)mark20;
}

#pragma mark - date（刻意不合并）

- (void)test_date_neverMerged {
    // 即使后端返回 date，客户端日期字段不应被改变
    KKParsedBookEntry *e = blankEntry();
    e.year = 2026; e.month = 8; e.day = 14;
    [KKLLMParser mergeData:@{@"price": @35.0, @"categoryName": @"交通", @"isIncome": @NO,
                              @"date": @"2026-08-13"}
                 intoEntry:e categories:self.cats];
    XCTAssertEqual(e.year,  2026, @"date 不应被 LLM 覆盖");
    XCTAssertEqual(e.month, 8);
    XCTAssertEqual(e.day,   14);
}

@end
