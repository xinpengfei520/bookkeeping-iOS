/**
 * 分类
 * @author 郑业强 2018-12-17 创建文件
 */

#import <UIKit/UIKit.h>
#import "CategoryListModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CategoryTable : UITableView

@property (nonatomic, strong) CategoryListModel *model;

/// 编辑模式：控制 cell 操作控件显隐 + 是否允许侧滑删除
@property (nonatomic, assign) BOOL editingMode;

+ (instancetype)initWithFrame:(CGRect)frame;

@end

NS_ASSUME_NONNULL_END
