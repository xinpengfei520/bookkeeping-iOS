/**
 * 定时
 * @author 郑业强 2018-12-18 创建文件
 */

#import <MGSwipeTableCell/MGSwipeTableCell.h>

@interface TITableCell : MGSwipeTableCell

@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) NSString *time;

@end
