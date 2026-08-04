//
//  DateWeekdayTests.m
//  bookkeepingTests
//
//  首页"星期"的纯数学计算（NSDate+Extension kk_weekdayCNFromYear:month:day:）。
//  返回值经过 KKLocalized，中英文模式下文案不同 —— 所以断言结构性质
//  （七日循环、同星期日子相等、永不为空），不锁具体文案。
//

#import <XCTest/XCTest.h>

@interface NSDate (KKWeekdayTest)
+ (NSString *)kk_weekdayCNFromYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day;
@end


@interface DateWeekdayTests : XCTestCase
@end

@implementation DateWeekdayTests

- (void)testNeverBlank {
    // 这个方法就是为了修"星期偶发空白"才改成纯数学的，空串即回归
    for (NSInteger day = 1; day <= 28; day++) {
        NSString *w = [NSDate kk_weekdayCNFromYear:2026 month:8 day:day];
        XCTAssertTrue(w.length > 0, @"2026-08-%02ld 星期为空", (long)day);
    }
}

- (void)testSevenDayCycle {
    // 连续 7 天两两不同，第 8 天回到第 1 天
    NSMutableSet *week = [NSMutableSet set];
    for (NSInteger day = 1; day <= 7; day++) {
        [week addObject:[NSDate kk_weekdayCNFromYear:2026 month:8 day:day]];
    }
    XCTAssertEqual(week.count, 7);
    XCTAssertEqualObjects([NSDate kk_weekdayCNFromYear:2026 month:8 day:8],
                          [NSDate kk_weekdayCNFromYear:2026 month:8 day:1]);
}

- (void)testKnownSameWeekdayAnchors {
    // 2000-01-01 与 2026-08-01 都是星期六（跨世纪 + 多个闰年的锚点对）
    XCTAssertEqualObjects([NSDate kk_weekdayCNFromYear:2000 month:1 day:1],
                          [NSDate kk_weekdayCNFromYear:2026 month:8 day:1]);
    // 2024-02-29（闰日）与 2024-03-07 同为星期四
    XCTAssertEqualObjects([NSDate kk_weekdayCNFromYear:2024 month:2 day:29],
                          [NSDate kk_weekdayCNFromYear:2024 month:3 day:7]);
}

- (void)testLeapYearBoundary {
    // 闰年 2/29 的后一天是 3/1，星期应当连续（相差一天不相等，隔 7 天相等）
    XCTAssertNotEqualObjects([NSDate kk_weekdayCNFromYear:2024 month:2 day:29],
                             [NSDate kk_weekdayCNFromYear:2024 month:3 day:1]);
    XCTAssertEqualObjects([NSDate kk_weekdayCNFromYear:2024 month:2 day:29],
                          [NSDate kk_weekdayCNFromYear:2024 month:3 day:7]);
}

@end
