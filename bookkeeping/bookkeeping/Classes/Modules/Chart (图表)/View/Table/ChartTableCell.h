/**
 * 图表
 * @author 郑业强 2018-12-18 创建文件
 */

#import "BaseTableCell.h"
#import "BookDetailModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChartTableCell : BaseTableCell

@property (nonatomic, assign) CGFloat maxPrice;
@property (nonatomic, strong) BookDetailModel *model;
//@property (nonatomic, strong) BookGroupModel *model;
// 是否是记账详情，如果是记账详情，则显示记账备注，否则显示记账类别名
@property (nonatomic, assign, readwrite) BOOL isBookDetail;

@end

NS_ASSUME_NONNULL_END
