/**
 * 我的列表Cell
 * @author 郑业强 2018-12-16 创建文件
 */

#import "MineTableCell.h"

#pragma mark - 声明
@interface MineTableCell()

@end


#pragma mark - 实现
@implementation MineTableCell


- (void)initUI {
    [self.sw setOnTintColor:kColor_Main_Color];
    [self.nameLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.nameLab setTextColor:kColor_Text_Black];
    [self.detailLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.detailLab setTextColor:kColor_Text_Black];
    [self.sw addTarget:self action:@selector(swValueChange:) forControlEvents:UIControlEventValueChanged];
}


- (void)swValueChange:(UISwitch *)sw {
    NSLog(@"我的页面的第%ld行被点击了",_indexPath.row);
    if (_indexPath.row == 3) {
        [self routerEventWithName:MINE_FACE_ID_CLICK data:@(sw.on)];
    }
}


#pragma mark - set
// 样式
- (void)setStatus:(MineTableCellStatus)status {
    _status = status;
    if (status == MineTableCellStatusText) {
        self.sw.hidden = YES;
        self.detailLab.hidden = NO;
        self.nextIcn.hidden = NO;
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
    } else if (status == MineTableCellStatusSw) {
        self.sw.hidden = NO;
        self.detailLab.hidden = YES;
        self.nextIcn.hidden = YES;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
}


@end
