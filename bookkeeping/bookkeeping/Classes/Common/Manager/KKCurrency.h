/**
 * 多币种记账 —— 币种元数据 + 金额换算
 *
 * 设计地基（后端《记账APP端对接说明》）：
 *   1. book_detail.price 永远是人民币。外币记账时存的是**换算后**的人民币，
 *      首页合计 / 分类统计 / 图表继续直接对 price 求和，不需要任何改动。
 *   2. 原始外币信息存在三个可空字段 currency / originalPrice / exchangeRate 里，
 *      要么全给、要么全不给。人民币记账就是"全不给"。
 *   3. 汇率必须取自 GET /book/rates（服务端已按天缓存、全平台统一口径），
 *      APP 不做本地缓存、也不接第三方汇率源。请求逻辑在 BookController，
 *      本类只做纯计算 —— BookDetailModel 会被 BookMonth widget 复用编译，
 *      而 widget 里没有网络层，所以这里不能碰 AFNManager。
 *
 * @author 2026-08-03 创建文件
 */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

// ISO-4217 币种代码。服务端要求大写，格式 ^[A-Z]{3}$
extern NSString * const KKCurrencyCNY;
extern NSString * const KKCurrencyUSD;
extern NSString * const KKCurrencyHKD;
extern NSString * const KKCurrencySGD;

@interface KKCurrency : NSObject

#pragma mark - 元数据
/// 记账页币种选择器的顺序：人民币在最前，默认选中
+ (NSArray<NSString *> *)supportedCodes;
/// 货币符号：CNY→¥ / USD→US$ / HKD→HK$ / SGD→S$（金额前缀用，如 "US$5.20"）
+ (NSString *)symbolForCode:(nullable NSString *)code;
/// 币种角标，统一的"符号+字母"形式：¥CNY / $USD / $HKD / $SGD
+ (NSString *)badgeForCode:(nullable NSString *)code;
/// 名称：人民币 / 美元 / 港币 / 新加坡元
+ (NSString *)nameForCode:(nullable NSString *)code;
/// 是否是需要留痕汇率的外币（CNY / 空值 / 不支持的代码都返回 NO）
+ (BOOL)isForeignCode:(nullable NSString *)code;

#pragma mark - 金额换算
/// price = round(originalPrice × exchangeRate, 2)。
/// 全程 NSDecimalNumber：直接用接口返回的 6 位汇率去乘，服务端会按同样方式复算，
/// 自己再对汇率做精度处理必然对不上（服务端只容忍 1 分的舍入误差）。
+ (CGFloat)cnyPriceForAmount:(CGFloat)amount rate:(CGFloat)rate;
/// 金额格式化，保留 2 位小数（price / originalPrice 的提交与展示口径）
+ (NSString *)formatAmount:(CGFloat)amount;
/// 汇率格式化，保留 6 位小数（数据库为 decimal(16,6)）
+ (NSString *)formatRate:(CGFloat)rate;
/// 带符号的原始金额，如 "US$5.20"
+ (NSString *)displayAmount:(CGFloat)amount code:(nullable NSString *)code;
/// 汇率描述，如 "1 USD = 6.752650 CNY"
+ (NSString *)displayRate:(CGFloat)rate code:(nullable NSString *)code;

@end

NS_ASSUME_NONNULL_END
