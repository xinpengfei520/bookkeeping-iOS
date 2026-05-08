//
//  BookChartModel.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/3.
//  Copyright © 2022 kk. All rights reserved.
//

#import "BookChartModel.h"

@implementation BookChartModel

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

// 统计数据(图表首页)
+ (BookChartModel *)statisticalChart:(NSInteger)segmentIndex isIncome:(BOOL)isIncome cmodel:(BookDetailModel *)cmodel date:(NSDate *)date arrm:(NSMutableArray<BookDetailModel *> *)arrm {
    
    NSMutableString *preStr = [NSMutableString string];
    if (cmodel) {
        [preStr appendFormat:@"categoryId == %ld", cmodel.categoryId];
    }else{
        if (isIncome) {
            [preStr appendFormat:@"categoryId >= %d", 33];
        }else{
            [preStr appendFormat:@"categoryId <= %d", 32];
        }
    }

    // 周(周日到周六 7 天的数据)
    if (segmentIndex == 0) {
        NSDate *start = [date offsetDays:-[date weekday] + 1];
        NSDate *end = [date offsetDays:7 - [date weekday]];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyyMMdd"];
        [formatter setTimeZone:[NSTimeZone localTimeZone]];
        NSInteger startStr = [[formatter stringFromDate:start] integerValue];
        NSInteger endStr = [[formatter stringFromDate:end] integerValue];
        
        [preStr appendFormat:@" AND dateNumber >= %ld AND dateNumber <= %ld", startStr, endStr];
    }
    // 月
    else if (segmentIndex == 1) {
        [preStr appendFormat:@" AND year == %ld AND month == %ld", date.year, date.month];
    }
    // 年
    else if (segmentIndex == 2) {
        [preStr appendFormat:@" AND year == %ld", date.year];
    }
    
    NSMutableArray<BookDetailModel *> *models = [NSMutableArray kk_filteredArrayUsingStringFormat:preStr array:arrm];
    NSMutableArray<BookDetailModel *> *chartArr = [NSMutableArray array];
    NSMutableArray<NSMutableArray<BookDetailModel *> *> *chartHudArr = [NSMutableArray array];
    
    // 周
    if (segmentIndex == 0) {
        NSDate *first = [date offsetDays:-[date weekday] + 1];
        for (int i=0; i<7; i++) {
            NSDate *date = [first offsetDays:i];
            BookDetailModel *model = [[BookDetailModel alloc] init];
            model.year = date.year;
            model.month = date.month;
            model.day = date.day;
            model.price = 0;
            [chartArr addObject:model];
            [chartHudArr addObject:[NSMutableArray array]];
        }
        
        for (BookDetailModel *model in models) {
            // 防御性：BookDetailModel.date 是 computed property（用 year/month/day 拼字符串
            // 给 NSDateFormatter），脏数据时可能返回 nil → [nil weekday] 返回 0 →
            // chartHudArr[-1] 数组越界（NSUInteger 溢出）。Apple weekday 应在 1..7。
            NSInteger weekday = (model.date != nil) ? [model.date weekday] : 0;
            if (weekday < 1 || weekday > 7) {
                continue;
            }
            NSDecimalNumber *number1 = [NSDecimalNumber decimalNumberWithString:[@(chartArr[7 - weekday].price) description]];
            NSDecimalNumber *number2 = [NSDecimalNumber decimalNumberWithString:[@(model.price) description]];
            number1 = [number1 decimalNumberByAdding:number2];
            chartArr[7 - weekday].price += [number1 doubleValue];
            [chartHudArr[weekday - 1] addObject:model];
        }
    }
    // 月
    else if (segmentIndex == 1) {
        NSInteger daysInMonth = [date daysInMonth];
        for (int i=1; i<=daysInMonth; i++) {
            BookDetailModel *model = [[BookDetailModel alloc] init];
            model.year = date.year;
            model.month = daysInMonth;
            model.day = i;
            model.price = 0;
            [chartArr addObject:model];
            [chartHudArr addObject:[NSMutableArray array]];
        }
        for (BookDetailModel *model in models) {
            // 防御性：脏数据 day 越界时跳过
            if (model.day < 1 || model.day > daysInMonth) {
                continue;
            }
            chartArr[model.day-1].price += model.price;
            [chartHudArr[model.day-1] addObject:model];
        }
    }
    // 年
    else if (segmentIndex == 2) {
        for (int i=1; i<=12; i++) {
            BookDetailModel *model = [[BookDetailModel alloc] init];
            model.year = date.year;
            model.month = i;
            model.day = 1;
            model.price = 0;
            [chartArr addObject:model];
            [chartHudArr addObject:[NSMutableArray array]];
        }
        for (BookDetailModel *model in models) {
            // 防御性：脏数据 month 越界时跳过
            if (model.month < 1 || model.month > 12) {
                continue;
            }
            chartArr[model.month-1].price += model.price;
            [chartHudArr[model.month-1] addObject:model];
        }
    }
    
    // 排序
    for (NSMutableArray *arrm in chartHudArr) {
        [arrm sortUsingComparator:^NSComparisonResult(BookDetailModel *obj1, BookDetailModel *obj2) {
            return obj1.price < obj2.price;
        }];
    }
    
    NSMutableArray<BookDetailModel *> *groupArr = [NSMutableArray array];
    if (!cmodel) {
        for (BookDetailModel *model in models) {
            NSInteger index = -1;
            for (NSInteger i=0; i<groupArr.count; i++) {
                BookDetailModel *submodel = groupArr[i];
                if (submodel.categoryId == model.categoryId) {
                    index = i;
                }
            }
            if (index == -1) {
                BookDetailModel *submodel = [model copy];
                [groupArr addObject:submodel];
            }
            else {
                NSDecimalNumber *number1 = [NSDecimalNumber decimalNumberWithString:[@(groupArr[index].price) description]];
                NSDecimalNumber *number2 = [NSDecimalNumber decimalNumberWithString:[@(model.price) description]];
                number1 = [number1 decimalNumberByAdding:number2];
                groupArr[index].price = [number1 doubleValue];
                //groupArr[index].price += model.price;
            }
        }
    } else {
        for (BookDetailModel *model in models) {
            BookDetailModel *submodel = [model copy];
            [groupArr addObject:submodel];
        }
    }
    
    [groupArr sortUsingComparator:^NSComparisonResult(BookDetailModel *obj1, BookDetailModel *obj2) {
        return obj1.price < obj2.price;
    }];
    
    BookChartModel *model = [[BookChartModel alloc] init];
    model.groupArr = groupArr;
    model.chartArr = chartArr;
    model.chartHudArr = chartHudArr;
    model.sum = [[chartArr valueForKeyPath:@"@sum.price.floatValue"] floatValue];
    model.max = [[chartArr valueForKeyPath:@"@max.price.floatValue"] floatValue];
    model.avg = [[NSString stringWithFormat:@"%.2f", model.sum / chartArr.count] floatValue];
    model.is_income = isIncome;
    return model;
}

@end
