/**
 * 今日汇率
 *
 * 从「我的」页面进入，只读展示 GET /book/rates 的结果：以人民币为基准的
 * 美元 / 港币 / 新加坡元汇率、生效日、数据源。记账页用的是同一个接口，
 * 所以这里看到的数字与记一笔外币时用的完全一致。
 */

#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface RateController : BaseViewController

@end

NS_ASSUME_NONNULL_END
