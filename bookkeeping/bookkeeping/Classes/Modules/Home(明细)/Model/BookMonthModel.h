//
//  BookMonthModel.h
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/3.
//  Copyright © 2022 kk. All rights reserved.
//

#import "BaseModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BookMonthModel : BaseModel<NSCoding>

@property (nonatomic, assign) NSInteger year;
@property (nonatomic, assign) NSInteger month;
@property (nonatomic, assign) NSInteger day;
@property (nonatomic, assign) CGFloat income;       // 收入
@property (nonatomic, assign) CGFloat pay;          // 支出
@property (nonatomic, strong) NSMutableArray<BookDetailModel *> *array;  // 数据

// 统计数据
+(NSMutableArray<BookMonthModel *> *)statisticalMonthWithYear:(NSInteger)year month:(NSInteger)month;
+(NSMutableArray<BookMonthModel *> *)searchWithKeyword:(NSString*)keyword;
-(NSString*)getMoneyDescribe;
-(NSString*)getDateDescribe;
-(NSString *)getDateDescribeWithYear;
-(NSMutableArray<BookDetailModel *> *)array;

@end

NS_ASSUME_NONNULL_END
