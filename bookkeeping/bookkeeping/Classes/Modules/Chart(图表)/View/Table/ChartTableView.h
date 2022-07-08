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
// 是否是记账详情，如果是记账详情，则显示记账备注，否则显示记账类别名
@property (nonatomic, assign, readwrite) BOOL isBookDetail;

+ (instancetype)initWithFrame:(CGRect)frame;

@end

NS_ASSUME_NONNULL_END
