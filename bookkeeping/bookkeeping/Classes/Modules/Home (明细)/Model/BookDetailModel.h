//
//  BookDetailModel.h
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/3.
//  Copyright © 2022 kk. All rights reserved.
//

#import "BaseModel.h"
#import "BKCIncomeModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BookDetailModel : BaseModel<NSCoding, NSCopying>

@property (nonatomic, assign) NSInteger bookId;
@property (nonatomic, assign) NSInteger categoryId;
@property (nonatomic, assign) CGFloat price;
@property (nonatomic, assign) NSInteger year;
@property (nonatomic, assign) NSInteger month;
@property (nonatomic, assign) NSInteger day;
@property (nonatomic, assign) NSInteger week;
@property (nonatomic, copy  ) NSString *mark;
@property (nonatomic, copy  ) NSString *dateStr;    // 日期(例: 01月03日 星期五)
@property (nonatomic, strong) NSDate *date;         // 日期
@property (nonatomic, assign) NSInteger dateNumber; // 日期数字
@property (nonatomic, strong) BKCModel *cmodel;

// 获取Id
+ (NSNumber *)getId;
// 获取收支类型描述
-(NSString *)getTypeDesc;
// 获取价格描述
-(NSString *)getPriceStr;

@end

NS_ASSUME_NONNULL_END
