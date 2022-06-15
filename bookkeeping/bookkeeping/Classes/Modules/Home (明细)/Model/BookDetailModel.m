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
    NSString *str = [NSString stringWithFormat:@"%ld-%02ld-%02ld", _year, _month, _day];
    NSDate *date = [NSDate dateWithYMD:str];
    return [NSString stringWithFormat:@"%ld年%02ld月%02ld日   %@", _year, _month, _day, [date dayFromWeekday]];
}

-(NSString *)getTypeDesc{
    if (_categoryId <= 32) {
        return @"支出";
    }else{
        return @"收入";
    }
}

-(NSString *)getPriceStr{
    return [NSString stringWithFormat:@"%0.2f", _price];
}

- (NSDate *)date {
    return [NSDate dateWithYMD:[NSString stringWithFormat:@"%ld-%02ld-%02ld", _year, _month, _day]];
}

- (NSInteger)dateNumber {
    return [[NSString stringWithFormat:@"%ld%02ld%02ld", _year, _month, _day] integerValue];
}

- (NSInteger)week {
    return [self.date weekOfYear];
}

// 获取 bookId
+ (NSNumber *)getBookId {
    NSNumber *bookId = [NSUserDefaults objectForKey:BookDetailModelId];
    if (!bookId) {
        bookId = @(0);
    }
    bookId = @([bookId integerValue] + 1);
    [NSUserDefaults setObject:bookId forKey:BookDetailModelId];
    return bookId;
}

@end
