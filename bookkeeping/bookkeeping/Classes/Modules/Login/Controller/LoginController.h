/**
 * 登录
 * @author 郑业强 2018-12-23 创建文件
 */

#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - type
typedef void (^LoginComplete) (void);

@interface LoginController : BaseViewController

@property (nonatomic, copy) LoginComplete complete;

@end

NS_ASSUME_NONNULL_END
