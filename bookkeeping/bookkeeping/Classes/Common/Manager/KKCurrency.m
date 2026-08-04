/**
 * 多币种记账 —— 币种元数据 + 金额换算
 * 说明见 KKCurrency.h。本文件同时被主 App 与 BookMonth widget 编译，只能依赖 Foundation。
 */

#import "KKCurrency.h"

NSString * const KKCurrencyCNY = @"CNY";
NSString * const KKCurrencyUSD = @"USD";
NSString * const KKCurrencyHKD = @"HKD";
NSString * const KKCurrencySGD = @"SGD";

@implementation KKCurrency

#pragma mark - 元数据

+ (NSArray<NSString *> *)supportedCodes {
    return @[KKCurrencyCNY, KKCurrencyUSD, KKCurrencyHKD, KKCurrencySGD];
}

+ (NSString *)symbolForCode:(NSString *)code {
    if ([code isEqualToString:KKCurrencyUSD]) return @"US$";
    if ([code isEqualToString:KKCurrencyHKD]) return @"HK$";
    if ([code isEqualToString:KKCurrencySGD]) return @"S$";
    return @"¥";
}

+ (NSString *)badgeForCode:(NSString *)code {
    NSString *known = [[self supportedCodes] containsObject:code] ? code : KKCurrencyCNY;
    // 角标一律用单字符符号：¥CNY / $USD / $HKD / $SGD。
    // 后面已经跟了三位代码，符号再带地区前缀（US$USD / HK$HKD）既重复又占宽度。
    NSString *symbol = [known isEqualToString:KKCurrencyCNY] ? @"¥" : @"$";
    return [NSString stringWithFormat:@"%@%@", symbol, known];
}

+ (NSString *)nameForCode:(NSString *)code {
    if ([code isEqualToString:KKCurrencyUSD]) return KKLocalized(@"美元");
    if ([code isEqualToString:KKCurrencyHKD]) return KKLocalized(@"港币");
    if ([code isEqualToString:KKCurrencySGD]) return KKLocalized(@"新加坡元");
    return KKLocalized(@"人民币");
}

+ (BOOL)isForeignCode:(NSString *)code {
    if (code.length != 3 || [code isEqualToString:KKCurrencyCNY]) {
        return NO;
    }
    return [[self supportedCodes] containsObject:code];
}

#pragma mark - 金额换算

+ (CGFloat)cnyPriceForAmount:(CGFloat)amount rate:(CGFloat)rate {
    if (rate <= 0 || amount <= 0) {
        return 0;
    }
    // 二进制浮点直接相乘再 round 会在 .005 边界上偶发偏一分，走十进制。
    NSDecimalNumber *a = [NSDecimalNumber decimalNumberWithString:[self formatAmount:amount]];
    NSDecimalNumber *r = [NSDecimalNumber decimalNumberWithString:[self formatRate:rate]];
    NSDecimalNumberHandler *handler = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
                                                                                            scale:2
                                                                                 raiseOnExactness:NO
                                                                                  raiseOnOverflow:NO
                                                                                 raiseOnUnderflow:NO
                                                                              raiseOnDivideByZero:NO];
    return (CGFloat)[[a decimalNumberByMultiplyingBy:r withBehavior:handler] doubleValue];
}

+ (NSString *)formatAmount:(CGFloat)amount {
    return [NSString stringWithFormat:@"%.2f", amount];
}

+ (NSString *)formatRate:(CGFloat)rate {
    return [NSString stringWithFormat:@"%.6f", rate];
}

+ (NSString *)displayAmount:(CGFloat)amount code:(NSString *)code {
    return [NSString stringWithFormat:@"%@%@", [self symbolForCode:code], [self formatAmount:amount]];
}

+ (NSString *)displayRate:(CGFloat)rate code:(NSString *)code {
    return [NSString stringWithFormat:@"1 %@ = %@ %@",
            code.length ? code : KKCurrencyCNY, [self formatRate:rate], KKCurrencyCNY];
}

@end
