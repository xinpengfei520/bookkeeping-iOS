/**
 * item
 * @author 郑业强 2018-12-17 创建文件
 */

#import "BaseCollectionCell.h"
#import "ChartSubModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChartDateCell : BaseCollectionCell

@property (nonatomic, strong) ChartSubModel *model;
@property (nonatomic, assign) BOOL choose;

@end

NS_ASSUME_NONNULL_END
