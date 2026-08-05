//
//  BookDetailModel.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/3.
//  Copyright © 2022 kk. All rights reserved.
//

#import "BookDetailModel.h"

#define BookDetailModelId @"BookDetailModelId"

@implementation BookDetailModel

+ (void)load {
    [BookDetailModel mj_setupIgnoredPropertyNames:^NSArray *{
        return @[@"date"];
    }];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    self = [NSObject decodeClass:self decoder:aDecoder];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [NSObject encodeClass:self encoder:aCoder];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    BookDetailModel *model = [[[self class] allocWithZone:zone] init];
    model.bookId = self.bookId;
    model.categoryId = self.categoryId;
    model.price = self.price;
    model.year = self.year;
    model.month = self.month;
    model.day = self.day;
    model.week = self.week;
    model.mark = self.mark;
    model.date = self.date;
    model.currency = self.currency;
    model.originalPrice = self.originalPrice;
    model.exchangeRate = self.exchangeRate;
    return model;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[BookDetailModel class]]) {
        return false;
    }
    BookDetailModel *model = object;
    if ([self bookId] == [model bookId]) {
        return true;
    }
    return false;
}

- (NSString *)getDateStr {
    // 星期用纯数学算（见 NSDate+Extension 的 kk_weekdayCNFromYear:month:day:）：
    // 不碰 NSDate/NSCalendar，结果确定、绝不为空。
    return [NSString stringWithFormat:KKLocalized(@"%ld年%02ld月%02ld日   %@"), _year, _month, _day, [NSDate kk_weekdayCNFromYear:_year month:_month day:_day]];
}

-(NSString *)getTypeDesc{
    if (_categoryId <= 32) {
        return KKLocalized(@"支出");
    }else{
        return KKLocalized(@"收入");
    }
}

-(NSString *)getPriceStr{
    // 如果没有小数
    if (fmodf(_price, 1)==0) {
        return [NSString stringWithFormat:@"%.0f",_price];
        // 如果有一位小数
    } else if (fmodf(_price*10, 1)==0) {
        return [NSString stringWithFormat:@"%.1f",_price];
        // 如果有两位小数
    } else {
        return [NSString stringWithFormat:@"%.2f",_price];
    }
}

- (BOOL)isForeignCurrency {
    // 三个字段"要么全给、要么全不给"，缺一就当人民币处理，避免强解包炸掉
    return [KKCurrency isForeignCode:_currency] && _originalPrice > 0 && _exchangeRate > 0;
}

- (NSString *)getOriginalPriceStr {
    if (![self isForeignCurrency]) {
        return nil;
    }
    return [KKCurrency displayAmount:_originalPrice code:_currency];
}

- (NSString *)getExchangeRateStr {
    if (![self isForeignCurrency]) {
        return nil;
    }
    return [KKCurrency displayRate:_exchangeRate code:_currency];
}

- (NSAttributedString *)listPriceAttributedText:(NSString *)priceText {
    return [self listPriceAttributedText:priceText
                               badgeFont:[UIFont systemFontOfSize:AdjustFont(9) weight:UIFontWeightLight]];
}

- (NSAttributedString *)listPriceAttributedText:(NSString *)priceText badgeFont:(UIFont *)badgeFont {
    NSString *text = priceText ?: @"";
    if (![self isForeignCurrency]) {
        return [[NSAttributedString alloc] initWithString:text];
    }
    NSString *badge = [NSString stringWithFormat:@"%@  ", [self getOriginalPriceStr]];
    NSMutableAttributedString *att = [[NSMutableAttributedString alloc] initWithString:badge
                                                                            attributes:@{
        NSFontAttributeName: badgeFont,
        NSForegroundColorAttributeName: kColor_Text_Gary,
    }];
    [att appendAttributedString:[[NSAttributedString alloc] initWithString:text]];
    return att;
}

- (void)clearCurrency {
    _currency = nil;
    _originalPrice = 0;
    _exchangeRate = 0;
}

- (NSDate *)date {
    return [NSDate dateWithYMD:[NSString stringWithFormat:@"%ld-%02ld-%02ld", _year, _month, _day]];
}

- (NSInteger)dateNumber {
    return [[NSString stringWithFormat:@"%ld%02ld%02ld", _year, _month, _day] integerValue];
}

-(NSString *)priceString{
    return [self getPriceStr];
}

- (NSInteger)week {
    return [self.date weekOfYear];
}

// 获取 bookId
+ (NSNumber *)getBookId {
    NSNumber *bookId = [NSUserDefaults objectForKey:BookDetailModelId];
    if (!bookId) {
        bookId = @(1000000);
    }
    bookId = @([bookId integerValue] + 1);
    [NSUserDefaults setObject:bookId forKey:BookDetailModelId];
    return bookId;
}

@end
