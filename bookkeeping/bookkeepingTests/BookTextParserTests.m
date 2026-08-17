//
//  BookTextParserTests.m
//  bookkeepingTests
//
//  语音记账文本解析器（KKBookTextParser）的单元测试。
//  解析不准的话术先在这里加用例，再去 KKBookTextParser.m 改规则。
//
//  referenceDate 固定为 2026-08-13（周三），方便断言相对日期。
//

#import <XCTest/XCTest.h>

// ===== 重声明：测试 target 不走主 target PCH，按需声明接口 =====

@interface KKParsedBookEntry : NSObject
@property (nonatomic, assign) double price;
@property (nonatomic, assign) NSInteger categoryId;
@property (nonatomic, assign) BOOL isIncome;
@property (nonatomic, assign) NSInteger year;
@property (nonatomic, assign) NSInteger month;
@property (nonatomic, assign) NSInteger day;
@property (nonatomic, copy  ) NSString *mark;
@property (nonatomic, copy  ) NSString *rawText;
@end

@interface BKCModel : NSObject
@property (nonatomic, assign) NSInteger Id;
@property (nonatomic, copy  ) NSString *name;
@property (nonatomic, assign) BOOL is_income;
@end

@interface MarkModel : NSObject
@property (nonatomic, assign) NSInteger markId;
@property (nonatomic, copy  ) NSString *markName;
@property (nonatomic, assign) NSInteger frequency;
@property (nonatomic, assign) NSInteger categoryId;
@end

@interface KKBookTextParser : NSObject
+ (KKParsedBookEntry *)parseText:(NSString *)text
                      categories:(NSArray *)categories
                   referenceDate:(NSDate *)referenceDate;
+ (KKParsedBookEntry *)parseText:(NSString *)text
                      categories:(NSArray *)categories
                           marks:(NSArray *)marks
                   referenceDate:(NSDate *)referenceDate;
@end


// ===== 辅助 =====

@interface BookTextParserTests : XCTestCase
@property (nonatomic, strong) NSDate *refDate;      // 2026-08-13
@property (nonatomic, strong) NSArray *categories;  // 精简测试类别表
@end

@implementation BookTextParserTests

- (void)setUp {
    // 固定基准日期 2026-08-13
    NSDateComponents *c = [[NSDateComponents alloc] init];
    c.year = 2026; c.month = 8; c.day = 13; c.hour = 12;
    self.refDate = [[NSCalendar currentCalendar] dateFromComponents:c];

    // 构造最小类别集合（支出在前，收入在后）
    NSMutableArray *cats = [NSMutableArray array];
    NSDictionary *payDefs = @{
        @1: @"餐饮", @2: @"交通", @3: @"购物", @4: @"日用",
        @5: @"住房", @6: @"医疗", @7: @"娱乐", @8: @"服饰",
    };
    NSDictionary *incomeDefs = @{
        @101: @"工资", @102: @"兼职", @103: @"退货",
    };
    for (NSNumber *cId in payDefs) {
        BKCModel *m = [[BKCModel alloc] init];
        m.Id = cId.integerValue; m.name = payDefs[cId]; m.is_income = NO;
        [cats addObject:m];
    }
    for (NSNumber *cId in incomeDefs) {
        BKCModel *m = [[BKCModel alloc] init];
        m.Id = cId.integerValue; m.name = incomeDefs[cId]; m.is_income = YES;
        [cats addObject:m];
    }
    self.categories = cats;
}

// 简写：解析一句话
- (KKParsedBookEntry *)parse:(NSString *)text {
    return [KKBookTextParser parseText:text categories:self.categories referenceDate:self.refDate];
}

#pragma mark - 日期解析

- (void)testDateToday {
    KKParsedBookEntry *e = [self parse:@"今天吃饭花了50块"];
    XCTAssertEqual(e.day, 13);
    XCTAssertEqual(e.month, 8);
    XCTAssertEqual(e.year, 2026);
}

- (void)testDateYesterday {
    KKParsedBookEntry *e = [self parse:@"昨天打车花了35块"];
    XCTAssertEqual(e.day, 12);
    XCTAssertEqual(e.month, 8);
}

- (void)testDateDayBeforeYesterday {
    KKParsedBookEntry *e = [self parse:@"前天买菜花了20元"];
    XCTAssertEqual(e.day, 11);
}

- (void)testDateThreeDaysAgo {
    KKParsedBookEntry *e = [self parse:@"大前天外卖花了45块"];
    XCTAssertEqual(e.day, 10);
}

- (void)testDateAbsoluteMonthDay {
    KKParsedBookEntry *e = [self parse:@"8月3号打车50块"];
    XCTAssertEqual(e.month, 8);
    XCTAssertEqual(e.day, 3);
}

- (void)testDateAbsoluteDayOnly {
    // 只说"X号"，月份应取基准月
    KKParsedBookEntry *e = [self parse:@"5号交房租2000元"];
    XCTAssertEqual(e.month, 8);
    XCTAssertEqual(e.day, 5);
}

- (void)testDateNoDateFallsToToday {
    KKParsedBookEntry *e = [self parse:@"买了杯奶茶18块"];
    XCTAssertEqual(e.day, 13);
    XCTAssertEqual(e.month, 8);
}

#pragma mark - 金额解析

- (void)testAmountArabicWithUnit {
    XCTAssertEqualWithAccuracy([self parse:@"花了35块"].price, 35.0, 0.001);
    XCTAssertEqualWithAccuracy([self parse:@"花了35.5元"].price, 35.5, 0.001);
    XCTAssertEqualWithAccuracy([self parse:@"花了35块8"].price, 35.8, 0.001);
}

- (void)testAmountArabicDecimalUnit {
    // 35块八毛
    XCTAssertEqualWithAccuracy([self parse:@"打车35块八毛"].price, 35.8, 0.001);
}

- (void)testAmountChineseWithUnit {
    XCTAssertEqualWithAccuracy([self parse:@"三十五块"].price, 35.0, 0.001);
    XCTAssertEqualWithAccuracy([self parse:@"两百块"].price, 200.0, 0.001);
}

- (void)testAmountChineseHalfUnit {
    // 三块半
    XCTAssertEqualWithAccuracy([self parse:@"买了三块半的豆腐"].price, 3.5, 0.001);
}

- (void)testAmountSmallUnit {
    XCTAssertEqualWithAccuracy([self parse:@"五毛"].price, 0.5, 0.001);
    XCTAssertEqualWithAccuracy([self parse:@"5角"].price, 0.5, 0.001);
}

- (void)testAmountLargeWan {
    XCTAssertEqualWithAccuracy([self parse:@"房贷还了1万2"].price, 12000.0, 0.001);
}

- (void)testAmountBareArabic {
    // 裸数字兜底
    XCTAssertEqualWithAccuracy([self parse:@"打车花了35"].price, 35.0, 0.001);
}

- (void)testAmountVerbPrefixChinese {
    // 动词 + 裸中文数字
    XCTAssertEqualWithAccuracy([self parse:@"吃饭花了三十五"].price, 35.0, 0.001);
}

- (void)testAmountZeroWhenNone {
    // 没有金额信息
    XCTAssertEqualWithAccuracy([self parse:@"外出吃饭"].price, 0, 0.001);
}

- (void)testAmountDateNumberNotConfused {
    // "8月3号"不能被误识别成金额
    KKParsedBookEntry *e = [self parse:@"8月3号外卖花了50块"];
    XCTAssertEqualWithAccuracy(e.price, 50.0, 0.001);
    XCTAssertEqual(e.day, 3);
}

#pragma mark - 类别匹配

- (void)testCategoryDirectName {
    KKParsedBookEntry *e = [self parse:@"餐饮消费35块"];
    XCTAssertEqual(e.categoryId, 1);
    XCTAssertFalse(e.isIncome);
}

- (void)testCategorySynonymTransport {
    // 打车 → 交通
    KKParsedBookEntry *e = [self parse:@"昨天打车花了35块"];
    XCTAssertEqual(e.categoryId, 2);
}

- (void)testCategorySynonymFood {
    // 外卖 → 餐饮
    KKParsedBookEntry *e = [self parse:@"点外卖18块"];
    XCTAssertEqual(e.categoryId, 1);
}

- (void)testCategorySynonymHousing {
    // 房租 → 住房
    KKParsedBookEntry *e = [self parse:@"交房租2000"];
    XCTAssertEqual(e.categoryId, 5);
}

- (void)testCategoryIncomeHintSalary {
    // 工资 → 收入类别
    KKParsedBookEntry *e = [self parse:@"发工资8000元"];
    XCTAssertEqual(e.categoryId, 101);
    XCTAssertTrue(e.isIncome);
}

- (void)testCategoryIncomeHintRefund {
    // 退款 → 退货（收入）
    KKParsedBookEntry *e = [self parse:@"退款到账300元"];
    XCTAssertEqual(e.categoryId, 103);
    XCTAssertTrue(e.isIncome);
}

- (void)testCategoryNoMatch {
    // 说了一句话但没有类别关键词
    KKParsedBookEntry *e = [self parse:@"花了100块"];
    XCTAssertEqual(e.categoryId, -1);
}

#pragma mark - 备注提取

- (void)testMarkStripsFillerWords {
    KKParsedBookEntry *e = [self parse:@"昨天打车花了35块"];
    // "昨天"已被日期模块消耗，"花了"是填充词，"35块"是金额
    // 剩下的应该是"打车"或空串
    XCTAssertNotNil(e.mark);
}

- (void)testMarkNotEmpty {
    // 消费后有有意义的名词应能保留
    KKParsedBookEntry *e = [self parse:@"买了杯咖啡38块"];
    XCTAssertGreaterThan(e.mark.length, 0);
}

- (void)testMarkMaxLength {
    KKParsedBookEntry *e = [self parse:@"花了100块买了一堆零零碎碎的东西包括面膜洗面奶护肤水精华乳液防晒霜"];
    XCTAssertLessThanOrEqual(e.mark.length, 10);
}

- (void)testMarkPrefersExistingCategoryNote {
    // 「记一下晚饭」原文包含餐饮下已有备注「晚饭」，用已有备注而不是整句
    MarkModel *m = [[MarkModel alloc] init];
    m.categoryId = 1;   // 餐饮
    m.markName = @"晚饭";
    m.frequency = 3;
    KKParsedBookEntry *e = [KKBookTextParser parseText:@"记一下晚饭花了38块"
                                            categories:self.categories
                                                 marks:@[m]
                                         referenceDate:self.refDate];
    XCTAssertEqual(e.categoryId, 1);
    XCTAssertEqualObjects(e.mark, @"晚饭");
}

- (void)testMarkPrefersLongestExistingNote {
    MarkModel *shortMark = [[MarkModel alloc] init];
    shortMark.categoryId = 1;
    shortMark.markName = @"晚饭";
    MarkModel *longMark = [[MarkModel alloc] init];
    longMark.categoryId = 1;
    longMark.markName = @"公司晚饭";
    KKParsedBookEntry *e = [KKBookTextParser parseText:@"记一下公司晚饭花了80块"
                                            categories:self.categories
                                                 marks:@[shortMark, longMark]
                                         referenceDate:self.refDate];
    XCTAssertEqualObjects(e.mark, @"公司晚饭");
}

- (void)testMarkIgnoresOtherCategoryNotes {
    MarkModel *m = [[MarkModel alloc] init];
    m.categoryId = 2;   // 交通
    m.markName = @"晚饭";
    KKParsedBookEntry *e = [KKBookTextParser parseText:@"记一下晚饭花了38块"
                                            categories:self.categories
                                                 marks:@[m]
                                         referenceDate:self.refDate];
    // 餐饮下没有「晚饭」备注，退回同义词关键词
    XCTAssertEqual(e.categoryId, 1);
    XCTAssertEqualObjects(e.mark, @"晚饭");
}

- (void)testMarkStripsVoiceCommandToKeyword {
    KKParsedBookEntry *e = [self parse:@"记一下晚饭花了38块"];
    XCTAssertEqualObjects(e.mark, @"晚饭");
}

#pragma mark - rawText 保留

- (void)testRawTextPreserved {
    NSString *input = @"昨天打车花了三十五块八";
    KKParsedBookEntry *e = [self parse:input];
    XCTAssertEqualObjects(e.rawText, input);
}

- (void)testNilInputSafe {
    // nil 输入不崩
    KKParsedBookEntry *e = [KKBookTextParser parseText:nil
                                             categories:self.categories
                                          referenceDate:self.refDate];
    XCTAssertNotNil(e);
    XCTAssertEqualObjects(e.rawText, @"");
}

@end
