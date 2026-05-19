/**
 * 我的列表Cell (code-only — converted from MineTableCell.xib)
 * @author 郑业强 2018-12-16 创建文件
 */

#import "MineTableCell.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface MineTableCell()

@end


#pragma mark - 实现
@implementation MineTableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

- (void)buildSubviews {
    _icon = [[UIImageView alloc] init];
    _icon.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:_icon];

    _nameLab = [[UILabel alloc] init];
    [self.contentView addSubview:_nameLab];

    _nextIcn = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ad_arrow"]];
    _nextIcn.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:_nextIcn];

    _detailLab = [[UILabel alloc] init];
    [self.contentView addSubview:_detailLab];

    _sw = [[UISwitch alloc] init];
    [self.contentView addSubview:_sw];

    [_icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(countcoordinatesX(15));
        make.top.bottom.equalTo(self.contentView);
        make.width.equalTo(@(countcoordinatesX(20)));
    }];
    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_icon.mas_right).offset(countcoordinatesX(10));
        make.top.bottom.equalTo(self.contentView);
    }];
    [_nextIcn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-countcoordinatesX(15));
        make.top.bottom.equalTo(self.contentView);
        make.width.equalTo(@(countcoordinatesX(10)));
    }];
    [_detailLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self->_nextIcn.mas_left).offset(-countcoordinatesX(5));
        make.top.bottom.equalTo(self.contentView);
    }];
    // sw 的 trailing 与 nextIcn 的 trailing 对齐（XIB 原约束）
    [_sw mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self->_nextIcn.mas_right);
        make.centerY.equalTo(self.contentView);
    }];
}

- (void)initUI {
    [self.sw setOnTintColor:kColor_Main_Color];
    [self.nameLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.nameLab setTextColor:kColor_Text_Black];
    [self.detailLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.detailLab setTextColor:kColor_Text_Black];
    // valueChanged target 在 dequeue 复用时会被 SettingsController 显式 remove+add，
    // MineTableView 没有 sw 行，这里挂一次给残留的本地处理路径用即可。
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
    }
}


@end
