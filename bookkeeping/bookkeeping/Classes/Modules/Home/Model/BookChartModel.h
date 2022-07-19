//
//  BookChartModel.h
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/3.
//  Copyright © 2022 kk. All rights reserved.
//

#import "BaseModel.h"
#import "BookDetailModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BookChartModel : BaseModel<NSCoding>

@property (nonatomic, assign) CGFloat sum;                          // 总值
@property (nonatomic, assign) CGFloat max;                          // 最大值
@property (nonatomic, assign) CGFloat avg;                          // 平均值
@property (nonatomic, assign) BOOL is_income;                       // 是否是收入
@property (nonatomic, strong) NSMutableArray<BookDetailModel *> *groupArr;  // 排行榜
@property (nonatomic, strong) NSMutableArray<BookDetailModel *> *chartArr;  // 图表
@property (nonatomic, strong) NSMutableArray<NSMutableArray<BookDetailModel *> *> *chartHudArr;  // 图表

// 统计数据(图表首页)
+ (BookChartModel *)statisticalChart:(NSInteger)status isIncome:(BOOL)isIncome cmodel:(BookDetailModel *)cmodel date:(NSDate *)date arrm:(NSMutableArray<BookDetailModel *> *)arrm;

@end

NS_ASSUME_NONNULL_END
