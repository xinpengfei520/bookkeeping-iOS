//
//  CalculationTests.m
//  bookkeepingTests
//
//  记账键盘的加减算式求值（NSString+Calculation）。只断言数值，不锁字符串格式，
//  避免把 "3" / "3.00" 这类展示层差异误判为回归。
//

#import <XCTest/XCTest.h>

@interface NSString (KKCalculationTest)
+ (NSString *)calcComplexFormulaString:(NSString *)formula;
@end


@interface CalculationTests : XCTestCase
@end

@implementation CalculationTests

- (double)calc:(NSString *)formula {
    NSString *result = [NSString calcComplexFormulaString:formula];
    XCTAssertNotNil(result, @"公式 %@ 求值返回了 nil", formula);
    return [result doubleValue];
}

- (void)testAddition {
    XCTAssertEqualWithAccuracy([self calc:@"1+2"], 3, 0.001);
    XCTAssertEqualWithAccuracy([self calc:@"10.5+2.25"], 12.75, 0.001);
}

- (void)testSubtraction {
    XCTAssertEqualWithAccuracy([self calc:@"5-2.5"], 2.5, 0.001);
    XCTAssertEqualWithAccuracy([self calc:@"3-5"], -2, 0.001);
}

- (void)testMixed {
    XCTAssertEqualWithAccuracy([self calc:@"1+2-0.5"], 2.5, 0.001);
}

- (void)testDecimalPrecision {
    // 经典二进制浮点坑：0.1+0.2 应当收敛在分级精度内
    XCTAssertEqualWithAccuracy([self calc:@"0.1+0.2"], 0.3, 0.005);
}

@end
