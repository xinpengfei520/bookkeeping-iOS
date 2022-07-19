/**
 * 记账详情页
 * @author 郑业强 2019-01-05 创建
 */

#import "BaseViewController.h"
#import "BookDetailModel.h"

NS_ASSUME_NONNULL_BEGIN


#pragma mark - typedef
typedef void (^BDComplete)(void);
typedef void (^BDRefresh)(void);


#pragma mark - 声明
@interface BookDetailController : BaseViewController

@property (nonatomic, strong) BookDetailModel *model;
@property (nonatomic, copy  ) BDComplete complete;
@property (nonatomic, copy  ) BDRefresh refresh;

@end

NS_ASSUME_NONNULL_END
