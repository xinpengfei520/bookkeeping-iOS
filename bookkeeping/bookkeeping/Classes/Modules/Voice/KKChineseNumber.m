//
//  KKChineseNumber.m
//  bookkeeping
//

#import "KKChineseNumber.h"

// 数字字符 → 0~9；非数字返回 -1
static NSInteger KKDigitValue(unichar c) {
    switch (c) {
        case 0x96F6: case 0x3007: return 0;   // 零 〇
        case 0x4E00: return 1;                // 一
        case 0x4E8C: case 0x4E24: return 2;   // 二 两
        case 0x4E09: return 3;                // 三
        case 0x56DB: return 4;                // 四
        case 0x4E94: return 5;                // 五
        case 0x516D: return 6;                // 六
        case 0x4E03: return 7;                // 七
        case 0x516B: return 8;                // 八
        case 0x4E5D: return 9;                // 九
        default: return -1;
    }
}

// 单位字符 → 10/100/1000/10000/1e8；非单位返回 -1
static long long KKUnitValue(unichar c) {
    switch (c) {
        case 0x5341: return 10;               // 十
        case 0x767E: return 100;              // 百
        case 0x5343: return 1000;             // 千
        case 0x4E07: return 10000;            // 万
        case 0x4EBF: return 100000000;        // 亿
        default: return -1;
    }
}

@implementation KKChineseNumber

// 整数部分，三级分段：亿段(total) / 万段(section) / 万以内(subsec)。失败返回 -1
+ (long long)integerFromChinese:(NSString *)text {
    if (text.length == 0) return -1;
    long long total = 0;      // 亿及以上，已归位
    long long section = 0;    // 万段，已归位
    long long subsec = 0;     // 万以内的段
    NSInteger pending = -1;   // 读到但还没乘单位的数字
    long long lastUnit = 0;   // 最近一次单位（尾数口语简写的基准）
    BOOL sawZero = NO;        // 出现过「零」则尾数按字面个位算（三百零五=305）

    for (NSUInteger i = 0; i < text.length; i++) {
        unichar c = [text characterAtIndex:i];
        NSInteger d = KKDigitValue(c);
        if (d >= 0) {
            if (d == 0) { sawZero = YES; continue; }   // 「零」只是占位
            if (pending >= 0) return -1;               // 连续两个数字（三三）不合法
            pending = d;
            continue;
        }
        long long u = KKUnitValue(c);
        if (u < 0) return -1;
        if (u == 100000000) {
            long long v = total + section + subsec + (pending >= 0 ? pending : 0);
            if (v == 0) return -1;                     // 裸「亿」不合法
            total = v * u;
            section = 0; subsec = 0; pending = -1; lastUnit = u; sawZero = NO;
        } else if (u == 10000) {
            long long v = subsec + (pending >= 0 ? pending : 0);
            if (v == 0) return -1;                     // 裸「万」不合法
            section += v * u;
            subsec = 0; pending = -1; lastUnit = u; sawZero = NO;
        } else {
            // 十/百/千：段内累加；段首裸「十」按 1 算（十八=18）
            long long mult = (pending >= 0) ? pending : (u == 10 && subsec == 0 ? 1 : -1);
            if (mult < 0) return -1;                   // 「百」「千」前必须有数字
            subsec += mult * u;
            pending = -1; lastUnit = u; sawZero = NO;
        }
    }
    // 尾数：跟在单位后的孤立数字按口语简写乘 单位/10（两百五=250、一万二=12000）；
    // 「十」的简写基准恰好是个位（三十五=35）；出现过「零」按字面算（三百零五=305）
    long long tail = 0;
    if (pending >= 0) {
        tail = (lastUnit >= 10 && !sawZero) ? pending * (lastUnit / 10) : pending;
    }
    return total + section + subsec + tail;
}

+ (double)numberFromChinese:(NSString *)text {
    if (text.length == 0) return NAN;
    if ([text isEqualToString:@"半"]) return 0.5;

    NSRange dot = [text rangeOfString:@"点"];
    NSString *intPart = (dot.location == NSNotFound) ? text : [text substringToIndex:dot.location];
    NSString *fracPart = (dot.location == NSNotFound) ? nil : [text substringFromIndex:NSMaxRange(dot)];

    long long intValue = [self integerFromChinese:intPart];
    if (intValue < 0) return NAN;

    double value = (double)intValue;
    if (fracPart) {
        if (fracPart.length == 0) return NAN;
        double scale = 0.1;
        for (NSUInteger i = 0; i < fracPart.length; i++) {
            NSInteger d = KKDigitValue([fracPart characterAtIndex:i]);
            if (d < 0) return NAN;                     // 小数部分只能是数字序列
            value += d * scale;
            scale /= 10;
        }
    }
    return value;
}

@end
