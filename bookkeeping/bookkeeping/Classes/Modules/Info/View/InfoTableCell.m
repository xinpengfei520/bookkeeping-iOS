/**
 * cell (code-only — converted from InfoTableCell.xib)
 * @author 郑业强 2018-12-22 创建文件
 */

#import "InfoTableCell.h"
#import <Masonry/Masonry.h>


#pragma mark - 声明
@interface InfoTableCell()

@property (nonatomic, strong) UILabel *nameLab;
@property (nonatomic, strong) UILabel *detailLab;
@property (nonatomic, strong) UIImageView *nextIcn;
@property (nonatomic, strong) UIImageView *icon;

@end


#pragma mark - 实现
@implementation InfoTableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

- (void)buildSubviews {
    _nameLab = [[UILabel alloc] init];
    [self.contentView addSubview:_nameLab];

    _detailLab = [[UILabel alloc] init];
    [self.contentView addSubview:_detailLab];

    _nextIcn = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ad_arrow"]];
    _nextIcn.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:_nextIcn];

    _icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"default_header"]];
    _icon.contentMode = UIViewContentModeScaleAspectFill;
    _icon.clipsToBounds = YES;
    [self.contentView addSubview:_icon];

    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(countcoordinatesX(15));
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
    // icon 的 trailing 与 nextIcn 的 trailing 对齐 → 头像贴在右边-15 处
    [_icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self->_nextIcn.mas_right);
        make.centerY.equalTo(self.contentView);
        make.width.height.equalTo(@(countcoordinatesX(30)));
    }];
}

- (void)initUI {
    [self.nameLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.nameLab setTextColor:kColor_Text_Black];
    [self.detailLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.detailLab setTextColor:kColor_Text_Gary];
    [self.icon.layer setCornerRadius:countcoordinatesX(30) / 2];
    [self.icon.layer setMasksToBounds:true];

    [self setSelectedBackgroundView:[[UIView alloc] initWithFrame:self.frame]];
    [self.selectedBackgroundView setBackgroundColor:kColor_BG];
}

#pragma mark - set
- (void)setStatus:(InfoTableCellStatus)status {
    _status = status;
    if (status == InfoTableCellStatusIcon) {
        self.detailLab.hidden = YES;
        self.nextIcn.hidden = YES;
        self.icon.hidden = NO;
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
    } else if (status == InfoTableCellStatusName) {
        self.detailLab.hidden = NO;
        self.nextIcn.hidden = YES;
        self.icon.hidden = YES;
        // 收起箭头宽度 + 箭头前的 gap，detailLab 直接贴到 -15
        [self.nextIcn mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@0);
        }];
        [self.detailLab mas_updateConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self->_nextIcn.mas_left).offset(0);
        }];
    } else if (status == InfoTableCellStatusNext) {
        self.detailLab.hidden = NO;
        self.nextIcn.hidden = NO;
        self.icon.hidden = YES;
        [self.nextIcn mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@(countcoordinatesX(10)));
        }];
        [self.detailLab mas_updateConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self->_nextIcn.mas_left).offset(-countcoordinatesX(5));
        }];
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
}

- (void)setIndexPath:(NSIndexPath *)indexPath {
    _indexPath = indexPath;
    self.status = ({
        InfoTableCellStatus status;
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                status = InfoTableCellStatusIcon;
            } else if (indexPath.row == 1 || indexPath.row == 5) {
                status = InfoTableCellStatusName;
            } else {
                status = InfoTableCellStatusNext;
            }
        } else {
            status = InfoTableCellStatusNext;
        }
        status;
    });

    if (indexPath.row == 4) {
        self.detailLab.textColor = kColor_Red_Color;
    } else {
        self.detailLab.textColor = kColor_Text_Gary;
    }

    // name
    NSArray *arr= @[
        @[KKLocalized(@"头像"), @"ID", KKLocalized(@"昵称"), KKLocalized(@"性别"), KKLocalized(@"手机号"), KKLocalized(@"邮箱")],
        @[KKLocalized(@"修改密码")],
        @[KKLocalized(@"删除账号")]
    ];
    [self setName:arr[indexPath.section][indexPath.row]];
}

- (void)setModel:(UserModel *)model {
    _model = model;
    if (_indexPath.section == 0) {
        if (_indexPath.row == 0) {
            [self.icon sd_setImageWithURL:[NSURL URLWithString:model.userAvatar]];
        } else if (_indexPath.row == 1) {
            [self setDetail:model.userId];
        } else if (_indexPath.row == 2) {
            [self setDetail:model.nickname];
        } else if (_indexPath.row == 3) {
            [self setDetail:model.sex==true?KKLocalized(@"男"):KKLocalized(@"女")];
        } else if (_indexPath.row == 4) {
            if (model.userName) {
                [self setDetail:model.userName];
                [self setStatus:InfoTableCellStatusNext];
                [self.detailLab setTextColor:kColor_Text_Gary];
            } else {
                [self setDetail:KKLocalized(@"未绑定")];
                [self setStatus:InfoTableCellStatusNext];
                [self.detailLab setTextColor:kColor_Red_Color];
            }
        }else if (_indexPath.row == 5) {
            [self setDetail:KKLocalized(@"未绑定")];
            [self setStatus:InfoTableCellStatusNext];
            [self.detailLab setTextColor:kColor_Red_Color];
        }
    }
}

- (void)setName:(NSString *)name {
    _name = name;
    _nameLab.text = name;
}

- (void)setDetail:(NSString *)detail {
    _detail = detail;
    _detailLab.text = detail;
}


@end
