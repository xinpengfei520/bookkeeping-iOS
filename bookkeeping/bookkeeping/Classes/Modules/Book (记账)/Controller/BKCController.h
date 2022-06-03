/**
 * 记账分类
 * @author 郑业强 2018-12-16 创建文件
 */

#import "BaseViewController.h"
#import "BookDetailModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BKCController : BaseViewController

@property (nonatomic, strong) BookDetailModel *model;
@property (copy, nonatomic) void(^bookModelBlock)(BookDetailModel *model);

@end

NS_ASSUME_NONNULL_END
