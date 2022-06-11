/**
 * 头视图
 * @author 郑业强 2018-12-16 创建文件
 */

#import "BaseView.h"
#import "BookMonthModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface HomeHeader : BaseView

@property (nonatomic, strong) NSDate *date;
//@property (nonatomic, assign) CGFloat pay;
//@property (nonatomic, assign) CGFloat income;
//@property (nonatomic, strong) BookDetailModel *model;
@property (nonatomic, strong) NSMutableArray<BookMonthModel *> *models;

@end

NS_ASSUME_NONNULL_END
