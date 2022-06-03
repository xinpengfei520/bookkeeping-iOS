/**
 * 列表
 * @author 郑业强 2018-12-18 创建文件
 */

#import <UIKit/UIKit.h>
#import "ChartSubModel.h"
#import "BookChartModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChartTableView : UITableView

@property (nonatomic, assign) NSInteger navigationIndex;
@property (nonatomic, assign) NSInteger segmentIndex;
//@property (nonatomic, strong) ChartSubModel *subModel;
//@property (nonatomic, strong) BKModel *model;
@property (nonatomic, strong) BookChartModel *model;

+ (instancetype)initWithFrame:(CGRect)frame;

@end

NS_ASSUME_NONNULL_END
