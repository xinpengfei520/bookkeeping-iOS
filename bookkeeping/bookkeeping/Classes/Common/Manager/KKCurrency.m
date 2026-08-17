/**
 * 多币种记账 —— 币种元数据 + 金额换算
 * 说明见 KKCurrency.h。本文件同时被主 App 与 BookMonth widget 编译，只能依赖 Foundation。
 */

#import "KKCurrency.h"

@interface KKCurrency ()
+ (BOOL)isISO4217Code:(NSString *)code;
@end

NSString * const KKCurrencyCNY = @"CNY";
NSString * const KKCurrencyUSD = @"USD";
NSString * const KKCurrencyHKD = @"HKD";
NSString * const KKCurrencySGD = @"SGD";
NSString * const KKCurrencyJPY = @"JPY";
NSString * const KKCurrencyKRW = @"KRW";
NSString * const KKCurrencyGBP = @"GBP";
NSString * const KKCurrencyEUR = @"EUR";
NSString * const KKCurrencyCAD = @"CAD";

@implementation KKCurrency

#pragma mark - 元数据

+ (NSArray<NSString *> *)supportedCodes {
    // 汇率页 / 记账选择器都以 GET /book/rates 的键为准；这里只是回退目录 + 排序权重。
    return @[KKCurrencyCNY, KKCurrencyUSD, KKCurrencyHKD, KKCurrencySGD,
             KKCurrencyJPY, KKCurrencyKRW, KKCurrencyGBP, KKCurrencyEUR, KKCurrencyCAD];
}

+ (NSArray<NSString *> *)foreignCodesFromRates:(NSDictionary *)rates {
    if (![rates isKindOfClass:[NSDictionary class]] || rates.count == 0) {
        return @[];
    }
    NSMutableArray<NSString *> *codes = [NSMutableArray array];
    [rates enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![key isKindOfClass:[NSString class]] || ![self isForeignCode:key]) {
            return;
        }
        if (![obj respondsToSelector:@selector(doubleValue)] || [obj doubleValue] <= 0) {
            return;
        }
        [codes addObject:key];
    }];
    NSArray<NSString *> *preferred = [self supportedCodes];
    [codes sortUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        NSUInteger ia = [preferred indexOfObject:a];
        NSUInteger ib = [preferred indexOfObject:b];
        BOOL aKnown = ia != NSNotFound;
        BOOL bKnown = ib != NSNotFound;
        if (aKnown && bKnown) {
            if (ia < ib) return NSOrderedAscending;
            if (ia > ib) return NSOrderedDescending;
            return NSOrderedSame;
        }
        if (aKnown) return NSOrderedAscending;
        if (bKnown) return NSOrderedDescending;
        return [a compare:b];
    }];
    return codes;
}

+ (NSString *)symbolForCode:(NSString *)code {
    if ([code isEqualToString:KKCurrencyUSD]) return @"US$";
    if ([code isEqualToString:KKCurrencyHKD]) return @"HK$";
    if ([code isEqualToString:KKCurrencySGD]) return @"S$";
    if ([code isEqualToString:KKCurrencyJPY]) return @"JP¥";
    if ([code isEqualToString:KKCurrencyKRW]) return @"₩";
    if ([code isEqualToString:KKCurrencyGBP]) return @"£";
    if ([code isEqualToString:KKCurrencyEUR]) return @"€";
    if ([code isEqualToString:KKCurrencyCAD]) return @"CA$";
    if ([self isForeignCode:code]) return [code stringByAppendingString:@" "];
    return @"¥";
}

+ (NSString *)badgeForCode:(NSString *)code {
    NSString *known = [self isISO4217Code:code] ? code : KKCurrencyCNY;
    // 角标一律用单字符符号：¥CNY / $USD / ¥JPY / ₩KRW / £GBP / €EUR。
    // 后面已经跟了三位代码，符号再带地区前缀（US$USD / HK$HKD）既重复又占宽度。
    NSString *symbol = @"$";
    if ([known isEqualToString:KKCurrencyCNY] || [known isEqualToString:KKCurrencyJPY]) {
        symbol = @"¥";
    } else if ([known isEqualToString:KKCurrencyKRW]) {
        symbol = @"₩";
    } else if ([known isEqualToString:KKCurrencyGBP]) {
        symbol = @"£";
    } else if ([known isEqualToString:KKCurrencyEUR]) {
        symbol = @"€";
    }
    return [NSString stringWithFormat:@"%@%@", symbol, known];
}

+ (NSString *)nameForCode:(NSString *)code {
    if ([code isEqualToString:KKCurrencyUSD]) return KKLocalized(@"美元");
    if ([code isEqualToString:KKCurrencyHKD]) return KKLocalized(@"港币");
    if ([code isEqualToString:KKCurrencySGD]) return KKLocalized(@"新加坡元");
    if ([code isEqualToString:KKCurrencyJPY]) return KKLocalized(@"日元");
    if ([code isEqualToString:KKCurrencyKRW]) return KKLocalized(@"韩元");
    if ([code isEqualToString:KKCurrencyGBP]) return KKLocalized(@"英镑");
    if ([code isEqualToString:KKCurrencyEUR]) return KKLocalized(@"欧元");
    if ([code isEqualToString:KKCurrencyCAD]) return KKLocalized(@"加拿大元");
    if ([self isForeignCode:code]) return code;
    return KKLocalized(@"人民币");
}

+ (BOOL)isISO4217Code:(NSString *)code {
    if (code.length != 3) {
        return NO;
    }
    unichar c0 = [code characterAtIndex:0];
    unichar c1 = [code characterAtIndex:1];
    unichar c2 = [code characterAtIndex:2];
    return c0 >= 'A' && c0 <= 'Z' && c1 >= 'A' && c1 <= 'Z' && c2 >= 'A' && c2 <= 'Z';
}

+ (BOOL)isForeignCode:(NSString *)code {
    return [self isISO4217Code:code] && ![code isEqualToString:KKCurrencyCNY];
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

#pragma mark - GET /book/rates 响应解析

+ (NSDictionary<NSString *, NSNumber *> *)ratesFromResponseData:(id)data {
    if (![data isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    id rates = ((NSDictionary *)data)[@"rates"];
    if (![rates isKindOfClass:[NSDictionary class]] || [rates count] == 0) {
        return nil;
    }
    return rates;
}

+ (BOOL)staleFromResponseData:(id)data {
    if (![data isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    return [((NSDictionary *)data)[@"stale"] boolValue];
}

@end
