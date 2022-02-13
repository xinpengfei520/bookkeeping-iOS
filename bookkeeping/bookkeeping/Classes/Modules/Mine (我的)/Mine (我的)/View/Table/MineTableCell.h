/**
 * 我的列表Cell
 * @author 郑业强 2018-12-16 创建文件
 */

#import "BaseTableCell.h"

NS_ASSUME_NONNULL_BEGIN


#pragma mark - NS_ENUM
typedef NS_ENUM(NSUInteger, MineTableCellStatus) {
    // 文本类型
    MineTableCellStatusText,
    // 开关类型
    MineTableCellStatusSw,
};


#pragma mark - 声明
@interface MineTableCell : BaseTableCell
// Item 的下标对象
@property (nonatomic, strong) NSIndexPath *indexPath;
// 开关控件
@property (weak, nonatomic) IBOutlet UISwitch *sw;
// 文字前面的 icon
@property (weak, nonatomic) IBOutlet UIImageView *icon;
// icon 后面的文字
@property (weak, nonatomic) IBOutlet UILabel *nameLab;
// 详情描述
@property (weak, nonatomic) IBOutlet UILabel *detailLab;
// 下一个 icon
@property (weak, nonatomic) IBOutlet UIImageView *nextIcn;
// TableCell 状态，文字或开关
@property (nonatomic, assign) MineTableCellStatus status;

@end

NS_ASSUME_NONNULL_END
