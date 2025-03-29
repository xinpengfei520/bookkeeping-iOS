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
            [self setDetail:model.sex==true?@"男":@"女"];
        } else if (_indexPath.row == 4) {
            if (model.userName) {
                [self setDetail:model.userName];
                [self setStatus:InfoTableCellStatusNext];
                [self.detailLab setTextColor:kColor_Text_Gary];
            } else {
                [self setDetail:@"未绑定"];
                [self setStatus:InfoTableCellStatusNext];
                [self.detailLab setTextColor:kColor_Red_Color];
            }
        } else if (_indexPath.row == 5) {
            if (model.email && model.email.length > 0) {
                [self setDetail:model.email];
                [self setStatus:InfoTableCellStatusNext];
                [self.detailLab setTextColor:kColor_Text_Gary];
            } else {
                [self setDetail:@"未绑定"];
                [self setStatus:InfoTableCellStatusNext];
                [self.detailLab setTextColor:kColor_Red_Color];
            }
        }
    }
} 