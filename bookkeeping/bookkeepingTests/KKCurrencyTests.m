//
//  KKCurrencyTests.m
//  bookkeepingTests
//
//  多币种换算与格式化。price = round(originalPrice × exchangeRate, 2) 是与服务端
//  复算校验对齐的口径（允许 1 分误差），这里锁死客户端侧的行为。
//
//  测试通过 BUNDLE_LOADER 链接宿主 App 的符号 —— 下面只重声明用到的接口，
//  不 import 业务头文件，避免把 PCH / Pods 拖进测试 target。
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>

@interface KKCurrency : NSObject
+ (NSArray<NSString *> *)supportedCodes;
+ (NSArray<NSString *> *)foreignCodesFromRates:(NSDictionary *)rates;
+ (NSString *)symbolForCode:(NSString *)code;
+ (NSString *)badgeForCode:(NSString *)code;
+ (NSString *)nameForCode:(NSString *)code;
+ (BOOL)isForeignCode:(NSString *)code;
+ (CGFloat)cnyPriceForAmount:(CGFloat)amount rate:(CGFloat)rate;
+ (NSString *)formatAmount:(CGFloat)amount;
+ (NSString *)formatRate:(CGFloat)rate;
+ (NSString *)displayAmount:(CGFloat)amount code:(NSString *)code;
+ (NSString *)displayRate:(CGFloat)rate code:(NSString *)code;
@end


@interface KKCurrencyTests : XCTestCase
@end

@implementation KKCurrencyTests

#pragma mark - 换算

- (void)testCnyPriceMatchesServerContract {
    // 文档样例：5.20 USD × 6.752650 = 35.113780 → 35.11
    XCTAssertEqualWithAccuracy([KKCurrency cnyPriceForAmount:5.20 rate:6.752650], 35.11, 0.0001);
    // 整数金额
    XCTAssertEqualWithAccuracy([KKCurrency cnyPriceForAmount:100 rate:0.861030], 86.10, 0.0001);
    // 进位到分
    XCTAssertEqualWithAccuracy([KKCurrency cnyPriceForAmount:12.34 rate:5.268982], 65.02, 0.0001);
}

- (void)testCnyPriceInvalidInputsReturnZero {
    XCTAssertEqual([KKCurrency cnyPriceForAmount:0 rate:6.75], 0);
    XCTAssertEqual([KKCurrency cnyPriceForAmount:5.20 rate:0], 0);
    XCTAssertEqual([KKCurrency cnyPriceForAmount:-1 rate:6.75], 0);
    XCTAssertEqual([KKCurrency cnyPriceForAmount:5.20 rate:-1], 0);
}

#pragma mark - 格式化

- (void)testFormatKeepsSubmissionPrecision {
    // price / originalPrice 两位小数；exchangeRate 六位小数（decimal(16,6) 对齐）
    XCTAssertEqualObjects([KKCurrency formatAmount:5.2], @"5.20");
    XCTAssertEqualObjects([KKCurrency formatAmount:35.113], @"35.11");
    XCTAssertEqualObjects([KKCurrency formatRate:6.75265], @"6.752650");
    XCTAssertEqualObjects([KKCurrency formatRate:0.86103], @"0.861030");
}

- (void)testDisplayStrings {
    XCTAssertEqualObjects([KKCurrency displayAmount:5.2 code:@"USD"], @"US$5.20");
    XCTAssertEqualObjects([KKCurrency displayAmount:8 code:@"HKD"], @"HK$8.00");
    XCTAssertEqualObjects([KKCurrency displayAmount:1000 code:@"JPY"], @"JP¥1000.00");
    XCTAssertEqualObjects([KKCurrency displayAmount:20 code:@"EUR"], @"€20.00");
    XCTAssertEqualObjects([KKCurrency displayRate:6.75265 code:@"USD"], @"1 USD = 6.752650 CNY");
}

#pragma mark - 币种元数据

- (void)testBadgeIsSymbolPlusCode {
    XCTAssertEqualObjects([KKCurrency badgeForCode:@"CNY"], @"¥CNY");
    XCTAssertEqualObjects([KKCurrency badgeForCode:@"USD"], @"$USD");
    XCTAssertEqualObjects([KKCurrency badgeForCode:@"HKD"], @"$HKD");
    XCTAssertEqualObjects([KKCurrency badgeForCode:@"SGD"], @"$SGD");
    XCTAssertEqualObjects([KKCurrency badgeForCode:@"JPY"], @"¥JPY");
    XCTAssertEqualObjects([KKCurrency badgeForCode:@"KRW"], @"₩KRW");
    XCTAssertEqualObjects([KKCurrency badgeForCode:@"GBP"], @"£GBP");
    XCTAssertEqualObjects([KKCurrency badgeForCode:@"EUR"], @"€EUR");
    XCTAssertEqualObjects([KKCurrency badgeForCode:@"CAD"], @"$CAD");
    // 未知 ISO 代码仍用自身，不伪装成人民币；空值才回退
    XCTAssertEqualObjects([KKCurrency badgeForCode:@"AUD"], @"$AUD");
    XCTAssertEqualObjects([KKCurrency badgeForCode:nil], @"¥CNY");
}

- (void)testIsForeignCode {
    XCTAssertTrue([KKCurrency isForeignCode:@"USD"]);
    XCTAssertTrue([KKCurrency isForeignCode:@"HKD"]);
    XCTAssertTrue([KKCurrency isForeignCode:@"SGD"]);
    XCTAssertTrue([KKCurrency isForeignCode:@"JPY"]);
    XCTAssertTrue([KKCurrency isForeignCode:@"KRW"]);
    XCTAssertTrue([KKCurrency isForeignCode:@"GBP"]);
    XCTAssertTrue([KKCurrency isForeignCode:@"EUR"]);
    XCTAssertTrue([KKCurrency isForeignCode:@"CAD"]);
    XCTAssertTrue([KKCurrency isForeignCode:@"AUD"]);       // rates 多出来的 key 按 ISO 代码认
    XCTAssertFalse([KKCurrency isForeignCode:@"CNY"]);      // 人民币不是"外币"
    XCTAssertFalse([KKCurrency isForeignCode:@"usd"]);      // 服务端要求大写，小写不认
    XCTAssertFalse([KKCurrency isForeignCode:nil]);
    XCTAssertFalse([KKCurrency isForeignCode:@""]);
}

- (void)testSupportedCodesOrderCNYFirst {
    NSArray *codes = [KKCurrency supportedCodes];
    XCTAssertEqual(codes.count, 9);
    XCTAssertEqualObjects(codes.firstObject, @"CNY");   // 选择器默认项
    NSArray *expected = @[@"CNY", @"USD", @"HKD", @"SGD", @"JPY", @"KRW", @"GBP", @"EUR", @"CAD"];
    XCTAssertEqualObjects(codes, expected);
}

- (void)testForeignCodesFromRatesFollowsKeysNotHardcodedList {
    NSDictionary *rates = @{
        @"SGD": @5.268982,
        @"EUR": @7.797879,
        @"USD": @6.752650,
        @"AUD": @4.8,          // 接口后续新加的 key
        @"CNY": @1,            // 基准，不应出现
        @"usd": @6.75,         // 小写不认
        @"HKD": @0,            // 汇率无效
    };
    NSArray *codes = [KKCurrency foreignCodesFromRates:rates];
    // 已知币种按目录顺序，其余按字母序接后
    NSArray *expected = @[@"USD", @"SGD", @"EUR", @"AUD"];
    XCTAssertEqualObjects(codes, expected);
    XCTAssertEqual([KKCurrency foreignCodesFromRates:nil].count, 0);
    XCTAssertEqual([KKCurrency foreignCodesFromRates:@{}].count, 0);
}

@end
