/**
 * 汇率 7 天走势 sparkline
 *
 * 纯展示视图：给定按日期升序的汇率数组画一条折线，标注最高/最低值与首尾日期。
 * 数据由 RateController 逐日调 GET /book/rates?date= 汇集（服务端按天缓存）。
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKRateTrendView : UIView

/// 设置走势数据
/// @param values 按日期升序的汇率（1 外币 = N 人民币），允许个别缺失日已被剔除
/// @param dates  与 values 对齐的日期串（M/d 短格式用于首尾标注）
/// 少于 2 个点会显示"暂无走势"占位
- (void)setValues:(NSArray<NSNumber *> *)values dates:(NSArray<NSString *> *)dates;
/// 加载中占位
- (void)showLoading;
/// 失败占位
- (void)showEmpty;

@end

NS_ASSUME_NONNULL_END
