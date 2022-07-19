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
// 是否是记账详情，如果是记账详情，则显示记账备注，否则显示记账类别名
@property (nonatomic, assign, readwrite) BOOL isBookDetail;
@end

NS_ASSUME_NONNULL_END
