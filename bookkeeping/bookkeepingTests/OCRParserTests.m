//
//  OCRParserTests.m
//  bookkeepingTests
//
//  账单 OCR 文本 → 多条记账（KKBookTextParser parseReceiptText:）。
//  不跑 Vision；用真实账单/支付页常见排版喂文本。
//  referenceDate 固定 2026-08-17。
//

#import <XCTest/XCTest.h>

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

@interface KKBookTextParser : NSObject
+ (NSArray *)parseReceiptText:(NSString *)text
                   categories:(NSArray *)categories
                        marks:(NSArray *)marks
                referenceDate:(NSDate *)referenceDate;
@end

@interface OCRParserTests : XCTestCase
@property (nonatomic, strong) NSDate *refDate;
@property (nonatomic, strong) NSArray *categories;
@end

@implementation OCRParserTests

- (void)setUp {
    NSDateComponents *c = [[NSDateComponents alloc] init];
    c.year = 2026; c.month = 8; c.day = 17; c.hour = 12;
    self.refDate = [[NSCalendar currentCalendar] dateFromComponents:c];

    NSMutableArray *cats = [NSMutableArray array];
    NSDictionary *payDefs = @{
        @1: @"餐饮", @2: @"交通", @3: @"购物", @4: @"日用",
        @5: @"住房", @6: @"医疗", @7: @"娱乐", @8: @"服饰",
    };
    for (NSNumber *cId in payDefs) {
        BKCModel *m = [[BKCModel alloc] init];
        m.Id = cId.integerValue; m.name = payDefs[cId]; m.is_income = NO;
        [cats addObject:m];
    }
    self.categories = cats;
}

- (NSArray<KKParsedBookEntry *> *)parse:(NSString *)text {
    return [KKBookTextParser parseReceiptText:text
                                   categories:self.categories
                                        marks:nil
                                referenceDate:self.refDate];
}

- (void)testEmptyInput {
    XCTAssertEqual([self parse:@""].count, 0);
    XCTAssertEqual([self parse:nil].count, 0);
}

- (void)testWeChatPaySuccess {
    NSString *text = @"支付成功\n¥38.00\n星巴克\n零钱\n2026年8月13日 14:32:10";
    NSArray<KKParsedBookEntry *> *es = [self parse:text];
    XCTAssertEqual(es.count, 1);
    XCTAssertEqualWithAccuracy(es[0].price, 38.00, 0.001);
    XCTAssertEqual(es[0].year, 2026);
    XCTAssertEqual(es[0].month, 8);
    XCTAssertEqual(es[0].day, 13);
    XCTAssertEqual(es[0].categoryId, 1);   // 星巴克 → 餐饮（同义词没有星巴克，但「咖啡」不在。mark 可能是星巴克）
    XCTAssertTrue([es[0].mark containsString:@"星巴克"] || es[0].mark.length > 0);
}

- (void)testReceiptTotalBeatsLineItems {
    NSString *text = @"星巴克咖啡\n美式咖啡  32.00\n蛋糕  18.00\n合计  50.00";
    NSArray<KKParsedBookEntry *> *es = [self parse:text];
    XCTAssertEqual(es.count, 1);
    XCTAssertEqualWithAccuracy(es[0].price, 50.00, 0.001);
    XCTAssertEqual(es[0].categoryId, 1);
}

- (void)testTotalOnNextLine {
    NSString *text = @"星巴克\n合计\n50.00";
    NSArray<KKParsedBookEntry *> *es = [self parse:text];
    XCTAssertEqual(es.count, 1);
    XCTAssertEqualWithAccuracy(es[0].price, 50.00, 0.001);
}

- (void)testBillListMultipleDatedRows {
    NSString *text = @"2026/08/13  星巴克  38.00\n2026/08/13  滴滴出行  23.50\n2026/08/12  麦当劳  42.00";
    NSArray<KKParsedBookEntry *> *es = [self parse:text];
    XCTAssertEqual(es.count, 3);
    XCTAssertEqualWithAccuracy(es[0].price, 38.00, 0.001);
    XCTAssertEqualWithAccuracy(es[1].price, 23.50, 0.001);
    XCTAssertEqualWithAccuracy(es[2].price, 42.00, 0.001);
    XCTAssertEqual(es[0].day, 13);
    XCTAssertEqual(es[2].day, 12);
    XCTAssertEqual(es[1].categoryId, 2);   // 滴滴 → 交通
    XCTAssertEqual(es[2].categoryId, 1);   // 麦当劳 → 餐饮
}

- (void)testMonthDayWithoutYear {
    NSString *text = @"08-13  打车  35.00\n08-12  外卖  28.00";
    NSArray<KKParsedBookEntry *> *es = [self parse:text];
    XCTAssertEqual(es.count, 2);
    XCTAssertEqual(es[0].year, 2026);
    XCTAssertEqual(es[0].month, 8);
    XCTAssertEqual(es[0].day, 13);
    XCTAssertEqual(es[1].day, 12);
    XCTAssertEqual(es[0].categoryId, 2);
}

- (void)testCommaAmount {
    NSString *text = @"支付成功\n¥1,280.50\nApple Store";
    NSArray<KKParsedBookEntry *> *es = [self parse:text];
    XCTAssertEqual(es.count, 1);
    XCTAssertEqualWithAccuracy(es[0].price, 1280.50, 0.001);
}

- (void)testNegativeAmountIsExpense {
    NSString *text = @"交易成功\n-38.00\n星巴克咖啡";
    NSArray<KKParsedBookEntry *> *es = [self parse:text];
    XCTAssertEqual(es.count, 1);
    XCTAssertEqualWithAccuracy(es[0].price, 38.00, 0.001);
}

- (void)testDoesNotTreatDecimalMoneyAsDate {
    NSString *text = @"星巴克\n金额 38.00";
    NSArray<KKParsedBookEntry *> *es = [self parse:text];
    XCTAssertEqual(es.count, 1);
    XCTAssertEqualWithAccuracy(es[0].price, 38.00, 0.001);
    XCTAssertEqual(es[0].month, 8);
    XCTAssertEqual(es[0].day, 17);   // 没写出日期，用 referenceDate
}

- (void)testSkipsYearLikeBareNumber {
    NSString *text = @"订单详情\n2026\n星巴克";
    NSArray<KKParsedBookEntry *> *es = [self parse:text];
    XCTAssertEqual(es.count, 0);
}

- (void)testTimeIsNotAmount {
    NSString *text = @"支付成功\n14:32\n星巴克";
    NSArray<KKParsedBookEntry *> *es = [self parse:text];
    XCTAssertEqual(es.count, 0);
}

- (void)testYuanSuffix {
    NSString *text = @"打车花了 23.50元";
    NSArray<KKParsedBookEntry *> *es = [self parse:text];
    XCTAssertEqual(es.count, 1);
    XCTAssertEqualWithAccuracy(es[0].price, 23.50, 0.001);
    XCTAssertEqual(es[0].categoryId, 2);
}

- (void)testPayeeLabel {
    NSString *text = @"支付成功\n¥18.00\n收款方：瑞幸咖啡";
    NSArray<KKParsedBookEntry *> *es = [self parse:text];
    XCTAssertEqual(es.count, 1);
    XCTAssertEqualWithAccuracy(es[0].price, 18.00, 0.001);
    XCTAssertTrue([es[0].mark containsString:@"瑞幸"] || [es[0].mark containsString:@"咖啡"]);
}

- (void)testUndatedMerchantAmountList {
    NSString *text = @"星巴克  38.00\n滴滴出行  23.50";
    NSArray<KKParsedBookEntry *> *es = [self parse:text];
    XCTAssertEqual(es.count, 2);
    XCTAssertEqualWithAccuracy(es[0].price, 38.00, 0.001);
    XCTAssertEqualWithAccuracy(es[1].price, 23.50, 0.001);
    XCTAssertEqual(es[1].categoryId, 2);
}

@end
