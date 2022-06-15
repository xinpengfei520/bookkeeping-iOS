//
//  BookMonthModel.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/3.
//  Copyright © 2022 kk. All rights reserved.
//

#import "BookMonthModel.h"
#import "BookDetailModel.h"

@implementation BookMonthModel

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

- (NSString *)getDateDescribe {
    NSString *dateStr = [NSString stringWithFormat:@"%ld-%02ld-%02ld", _year, _month, _day];
    NSDate *date = [NSDate dateWithYMD:dateStr];
    return [NSString stringWithFormat:@"%02ld月%02ld日   %@", _month, _day, [date dayFromWeekday]];
}

- (NSString *)getMoneyDescribe {
    NSMutableString *strm = [NSMutableString string];
    if (_income != 0) {
        // 不要使用 [@(_income) description], 因为会导致精度问题
        NSString *strIncome=[NSString stringWithFormat:@"%0.2f", _income];
        [strm appendFormat:@"收入: %@", strIncome];
    }
    if (_income != 0 && _pay != 0) {
        [strm appendString:@"    "];
    }
    if (_pay != 0) {
        NSString *strPay=[NSString stringWithFormat:@"%0.2f", _pay];
        [strm appendFormat:@"支出: %@", strPay];
    }
    return strm;
}

- (NSMutableArray<BookDetailModel *> *)array{
    NSMutableArray *bookArray = [BookDetailModel mj_objectArrayWithKeyValuesArray:_list];
    return bookArray;
}

/**
 * 统计数据
 * @param year 年份
 * @param month 月份
 */
+ (NSMutableArray<BookMonthModel *> *)statisticalMonthWithYear:(NSInteger)year month:(NSInteger)month {
    // 根据时间过滤
    NSMutableArray<BookDetailModel *> *bookArr = [NSUserDefaults objectForKey:PIN_BOOK];
    NSString *preStr = [NSString stringWithFormat:@"year == %ld AND month == %ld", year, month];
//    NSPredicate *pre = [NSPredicate predicateWithFormat:preStr];
//    NSMutableArray<BookDetailModel *> *models = [NSMutableArray arrayWithArray:[bookArr filteredArrayUsingPredicate:pre]];
    NSMutableArray<BookDetailModel *> *models = [NSMutableArray kk_filteredArrayUsingPredicate:preStr array:bookArr];
    
    // 统计数据
    NSMutableDictionary *dictm = [NSMutableDictionary dictionary];
    for (BookDetailModel *detailModel in models) {
        NSString *key = [NSString stringWithFormat:@"%ld-%02ld-%02ld", detailModel.year, detailModel.month, detailModel.day];
        // 初始化
        if (![[dictm allKeys] containsObject:key]) {
            BookMonthModel *monthModel = [[BookMonthModel alloc] init];
            monthModel.year = detailModel.year;
            monthModel.month = detailModel.month;
            monthModel.day = detailModel.day;
            monthModel.array = [NSMutableArray array];
            monthModel.income = 0;
            monthModel.pay = 0;
            [dictm setObject:monthModel forKey:key];
        }
        // 添加数据
        BookMonthModel *submodel = dictm[key];
        //[submodel.list addObject:detailModel];
        // 收入
        if (detailModel.categoryId >= 33) {
            [submodel setIncome:submodel.income + detailModel.price];
        }else { // 支出
            [submodel setPay:submodel.pay + detailModel.price];
        }
        
        [dictm setObject:submodel forKey:key];
    }
    
    // 排序，按照 day 的倒序排
    NSMutableArray<BookMonthModel *> *arrm = [NSMutableArray arrayWithArray:[dictm allValues]];
    arrm = [NSMutableArray arrayWithArray:[arrm sortedArrayUsingComparator:^NSComparisonResult(BookMonthModel *obj1, BookMonthModel *obj2) {
        return obj2.day - obj1.day;
    }]];
    
    return arrm;
}

@end
