//
//  BookDetailModel.h
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/3.
//  Copyright © 2022 kk. All rights reserved.
//

#import <UIKit/UIKit.h>     // listPriceAttributedText 的 UIFont 参数；桥接头独立编译时没有 PCH 兜底
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

// ============ 多币种（外币记账才有，人民币记录这三个字段接口不会返回）============
// price 永远是人民币；下面三个只作留痕与展示，统计一律继续用 price。
// 三者满足 price ≈ originalPrice × exchangeRate（四舍五入到分）。
@property (nonatomic, copy  ) NSString *currency;      // 原始币种 ISO-4217，如 USD
@property (nonatomic, assign) CGFloat originalPrice;   // 原始币种下的金额
@property (nonatomic, assign) CGFloat exchangeRate;    // 记账当天 1 单位原始币种兑人民币的汇率

// 下面 3 个字段不是接口返回的字段，且不能删除，用于过滤数据
@property (nonatomic, assign) NSInteger week;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, assign) NSInteger dateNumber;
@property (nonatomic, copy  ) NSString *priceString;

// 获取 bookId
+ (NSNumber *)getBookId;
// 获取收支类型描述
-(NSString *)getTypeDesc;
// 获取价格描述(人民币)
-(NSString *)getPriceStr;
// 是否是外币记账(三个字段齐全才算)
-(BOOL)isForeignCurrency;
// 原始金额描述，如 "US$5.20"；不是外币时返回 nil
-(NSString *)getOriginalPriceStr;
// 汇率描述，如 "1 USD = 6.752650 CNY"；不是外币时返回 nil
-(NSString *)getExchangeRateStr;
// 清掉多币种三字段(切回人民币时用)
-(void)clearCurrency;
/// 列表行的金额展示：外币记录在人民币金额前加一个小号灰字的原始金额角标(如 "US$5.20 -35.11")，
/// 人民币记录原样返回，右侧金额的对齐位置不变。
-(NSAttributedString *)listPriceAttributedText:(NSString *)priceText;
/// 同上，但角标字体可指定（图表 tooltip 等金额本身就很小的场景，角标要再小一号）
-(NSAttributedString *)listPriceAttributedText:(NSString *)priceText badgeFont:(UIFont *)badgeFont;
// 获取日期(例: 2022年01月03日 星期五)
-(NSString *)getDateStr;

@end

NS_ASSUME_NONNULL_END
