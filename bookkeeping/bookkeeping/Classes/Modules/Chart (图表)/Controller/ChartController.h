/**
 * 图表
 * @author 郑业强 2018-12-16 创建文件
 */

#import "BaseViewController.h"
#import "BookDetailModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChartController : BaseViewController

// 导航栏下标：0 支出 1 收入
@property (nonatomic, assign) NSInteger navIndex;
@property (nonatomic, strong) BookDetailModel *cmodel;  // 单分类(支出/收入)

@end

NS_ASSUME_NONNULL_END
