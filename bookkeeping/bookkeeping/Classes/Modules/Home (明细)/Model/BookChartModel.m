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
+ (BookChartModel *)statisticalChart:(NSInteger)status isIncome:(BOOL)isIncome cmodel:(BookDetailModel *)cmodel date:(NSDate *)date {
    NSMutableString *preStr = [NSMutableString string];
    NSMutableArray *arrm = [NSUserDefaults objectForKey:PIN_BOOK];
    [preStr appendFormat:@"cmodel.is_income == %d", isIncome];
    if (cmodel) {
        [preStr appendFormat:@" AND cmodel.Id == %ld", cmodel.cmodel.Id];
    }

    // 周
    if (status == 0) {
        NSDate *start = [date offsetDays:-[date weekday] + 1];
        NSDate *end = [date offsetDays:7 - [date weekday]];
        NSDateFormatter *fora = [[NSDateFormatter alloc] init];
        [fora setDateFormat:@"yyyyMMdd"];
        [fora setTimeZone:[NSTimeZone localTimeZone]];
        NSInteger startStr = [[fora stringFromDate:start] integerValue];
        NSInteger endStr = [[fora stringFromDate:end] integerValue];
        
        [preStr appendFormat:@" AND dateNumber >= %ld AND dateNumber <= %ld", startStr, endStr];
    }
    // 月
    else if (status == 1) {
        [preStr appendFormat:@" AND year == %ld AND month == %ld", date.year, date.month];
    }
    // 年
    else if (status == 2) {
        [preStr appendFormat:@" AND year == %ld", date.year];
    }
    NSMutableArray<BookDetailModel *> *models = [NSMutableArray kk_filteredArrayUsingPredicate:preStr array:arrm];
    
    
    NSMutableArray<BookDetailModel *> *chartArr = [NSMutableArray array];
    NSMutableArray<NSMutableArray<BookDetailModel *> *> *chartHudArr = [NSMutableArray array];
    // 周
    if (status == 0) {
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
            NSDecimalNumber *number1 = [NSDecimalNumber decimalNumberWithString:[@(chartArr[7 - [model.date weekday]].price) description]];
            NSDecimalNumber *number2 = [NSDecimalNumber decimalNumberWithString:[@(model.price) description]];
            number1 = [number1 decimalNumberByAdding:number2];
            chartArr[7 - [model.date weekday]].price += [number1 doubleValue];
            [chartHudArr[[model.date weekday] - 1] addObject:model];
        }
    }
    // 月
    else if (status == 1) {
        for (int i=1; i<=[date daysInMonth]; i++) {
            BookDetailModel *model = [[BookDetailModel alloc] init];
            model.year = date.year;
            model.month = [date daysInMonth];
            model.day = i;
            model.price = 0;
            [chartArr addObject:model];
            [chartHudArr addObject:[NSMutableArray array]];
        }
        for (BookDetailModel *model in models) {
            chartArr[model.day-1].price += model.price;
            [chartHudArr[model.day-1] addObject:model];
        }
    }
    // 年
    else if (status == 2) {
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
                if (submodel.category_id == model.category_id) {
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
                
//                groupArr[index].price += model.price;
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
