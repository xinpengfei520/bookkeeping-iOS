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

- (NSString *)getDateDescribeWithYear {
    NSString *dateStr = [NSString stringWithFormat:@"%ld-%02ld-%02ld", _year, _month, _day];
    NSDate *date = [NSDate dateWithYMD:dateStr];
    return [NSString stringWithFormat:@"%ld年%02ld月%02ld日   %@", _year,_month, _day, [date dayFromWeekday]];
}

- (NSString *)getMoneyDescribe {
    NSMutableString *strm = [NSMutableString string];
    if (_income != 0) {
        [strm appendFormat:@"收入: %@", [self getPriceStr:_income]];
    }
    if (_income != 0 && _pay != 0) {
        [strm appendString:@"    "];
    }
    if (_pay != 0) {
        [strm appendFormat:@"支出: %@", [self getPriceStr:_pay]];
    }
    return strm;
}

-(NSString *)getPriceStr:(CGFloat)price{
    // 如果没有小数
    if (fmodf(price, 1)==0) {
        return [NSString stringWithFormat:@"%.0f",price];
        // 如果有一位小数
    } else if (fmodf(price*10, 1)==0) {
        return [NSString stringWithFormat:@"%.1f",price];
        // 如果有两位小数
    } else {
        return [NSString stringWithFormat:@"%.2f",price];
    }
}

/**
 * 统计数据 (根据年、月过滤)
 * @param year 年份
 * @param month 月份
 */
+ (NSMutableArray<BookMonthModel *> *)statisticalMonthWithYear:(NSInteger)year month:(NSInteger)month {
    NSMutableArray<BookDetailModel *> *bookArr = [NSUserDefaults objectForKey:All_BOOK_LIST];
    NSString *preStr = [NSString stringWithFormat:@"year == %ld AND month == %ld", year, month];
    NSMutableArray<BookDetailModel *> *models = [NSMutableArray kk_filteredArrayUsingStringFormat:preStr array:bookArr];
    return [self assembleData:models sortType:1];
}

+(NSMutableArray<BookMonthModel *> *)searchWithKeyword:(NSString*)keyword{
    NSPredicate *predicate = nil;
    // 判断输入的是否是金额
    if ([NSString isIntOrFloat:keyword]) {
        predicate = [NSPredicate predicateWithFormat:@"%K == %@",@"priceString", keyword];
    }else{
        // 根据 categoryId、mark 过滤
        NSInteger categoryId = [NSUserDefaults getCategoryId:keyword];
        predicate = [NSPredicate predicateWithFormat:@"categoryId == %ld OR %K contains %@", categoryId,@"mark", keyword];
    }
    
    NSMutableArray<BookDetailModel *> *bookArr = [NSUserDefaults objectForKey:All_BOOK_LIST];
    NSMutableArray<BookDetailModel *> *models = [NSMutableArray kk_filteredArrayUsingPredicate:predicate array:bookArr];
    return [self assembleData:models sortType:2];
}

/**
 * 组装数据
 * @param models 数据
 * @param sortType 排序类型：1 使用 day 字段排序，2 使用 year month day 字段排序
 */
+(NSMutableArray<BookMonthModel *> *)assembleData:(NSMutableArray<BookDetailModel *> *)models sortType:(NSInteger)sortType{
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
        [submodel.array addObject:detailModel];
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
    if (sortType == 1) {
        arrm = [NSMutableArray arrayWithArray:[arrm sortedArrayUsingComparator:^NSComparisonResult(BookMonthModel *obj1, BookMonthModel *obj2) {
            return obj2.day - obj1.day;
        }]];
    }else{
        NSSortDescriptor *yearDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"year" ascending:NO];
        NSSortDescriptor *monthDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"month" ascending:NO];
        NSSortDescriptor *dayDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"day" ascending:NO];
        // 这里的排序是: 首先按照 year 排序, 然后是 month, 最后按照 day
        NSArray *descriptorArray = [NSArray arrayWithObjects:yearDescriptor, monthDescriptor, dayDescriptor, nil];
        [arrm sortUsingDescriptors:descriptorArray];
    }
    
    return arrm;
}

/**
 * 重装数据 (将新数据添加到内存中旧数据的集合中)
 * 内存级别操作，毫秒级，缩短耗时，提升用户体验
 * @param models 内存中旧数据集合
 * @param model   新增记账的新数据
 */
+(NSMutableArray<BookMonthModel *> *)addData:(NSMutableArray<BookMonthModel *> *)models model:(BookDetailModel *)model {
    NSString *modelDate = [NSString stringWithFormat:@"%ld-%02ld-%02ld", model.year, model.month, model.day];
    
    BOOL isFind = NO;
    for (BookMonthModel *monthModel in models) {
        NSString *date = [NSString stringWithFormat:@"%ld-%02ld-%02ld", monthModel.year, monthModel.month, monthModel.day];
        if ([date isEqualToString:modelDate]) {
            // 添加数据
            [monthModel.array addObject:model];
            // 收入
            if (model.categoryId >= 33) {
                [monthModel setIncome:monthModel.income + model.price];
            }else { // 支出
                [monthModel setPay:monthModel.pay + model.price];
            }
            
            isFind = YES;
            break;
        }
    }
    
    if (!isFind) {
        BookMonthModel *monthModel = [[BookMonthModel alloc] init];
        monthModel.year = model.year;
        monthModel.month = model.month;
        monthModel.day = model.day;
        monthModel.array = [NSMutableArray array];
        monthModel.income = 0;
        monthModel.pay = 0;
        
        // 添加数据
        [monthModel.array addObject:model];
        // 收入
        if (model.categoryId >= 33) {
            [monthModel setIncome:monthModel.income + model.price];
        }else { // 支出
            [monthModel setPay:monthModel.pay + model.price];
        }
        
        [models addObject:monthModel];
    }
    
    // 排序，按照 day 的倒序排
    models = [NSMutableArray arrayWithArray:[models sortedArrayUsingComparator:^NSComparisonResult(BookMonthModel *obj1, BookMonthModel *obj2) {
        return obj2.day - obj1.day;
    }]];
    
    return models;
}

/**
 * 替换数据：内存级别操作
 */
+(NSMutableArray<BookMonthModel *> *)replaceData:(NSMutableArray<BookMonthModel *> *)models model:(BookDetailModel *)model bookId:(NSInteger)bookId {
    NSString *modelDate = [NSString stringWithFormat:@"%ld-%02ld-%02ld", model.year, model.month, model.day];
    
    for (BookMonthModel *monthModel in models) {
        NSString *date = [NSString stringWithFormat:@"%ld-%02ld-%02ld", monthModel.year, monthModel.month, monthModel.day];
        if ([date isEqualToString:modelDate]) {
            for (BookDetailModel *detailModel in monthModel.array) {
                if (detailModel.bookId == bookId) {
                    detailModel.bookId = model.bookId;
                    break;
                }
            }
            break;
        }
    }
    
    return models;
}

/**
 * 移除数据：内存级别操作
 */
+(NSMutableArray<BookMonthModel *> *)removeData:(NSMutableArray<BookMonthModel *> *)models model:(BookDetailModel *)model {
    NSString *modelDate = [NSString stringWithFormat:@"%ld-%02ld-%02ld", model.year, model.month, model.day];
    
    for (BookMonthModel *monthModel in models) {
        NSString *date = [NSString stringWithFormat:@"%ld-%02ld-%02ld", monthModel.year, monthModel.month, monthModel.day];
        if ([date isEqualToString:modelDate]) {
            for (BookDetailModel *detailModel in monthModel.array) {
                if (detailModel.bookId == model.bookId) {
                    [monthModel.array removeObject:detailModel];
                    break;
                }
            }
            [monthModel refresh];
            break;
        }
    }
    
    return models;
}

-(void)refresh {
    self.income = 0;
    self.pay = 0;
    for (BookDetailModel *model in self.array) {
        if (model.categoryId >= 33) {
            [self setIncome:self.income + model.price];
        }else {
            [self setPay:self.pay + model.price];
        }
    }
}

@end
