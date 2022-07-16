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
@property (nonatomic, copy  ) NSString *mark;
// 下面 3 个字段不是接口返回的字段，且不能删除，用于过滤数据
@property (nonatomic, assign) NSInteger week;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, assign) NSInteger dateNumber;
@property (nonatomic, copy  ) NSString *priceString;

// 获取 bookId
+ (NSNumber *)getBookId;
// 获取收支类型描述
-(NSString *)getTypeDesc;
// 获取价格描述
-(NSString *)getPriceStr;
// 获取日期(例: 2022年01月03日 星期五)
-(NSString *)getDateStr;

@end

NS_ASSUME_NONNULL_END
