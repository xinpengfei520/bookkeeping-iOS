//
//  BDTableCell.m (code-only — converted from BDTableCell.xib)
//  bookkeeping
//
//  Created by 郑业强 on 2019/1/6.
//  Copyright © 2019年 kk. All rights reserved.
//

#import "BDTableCell.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface BDTableCell()

@property (nonatomic, strong) UILabel *nameLab;
@property (nonatomic, strong) UILabel *detailLab;

@end


#pragma mark - 实现
@implementation BDTableCell

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

    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(countcoordinatesX(15));
        make.top.bottom.equalTo(self.contentView);
    }];
    [_detailLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_nameLab.mas_right).offset(20);
        make.top.bottom.equalTo(self.contentView);
    }];
}

- (void)initUI {
    [self.nameLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.nameLab setTextColor:kColor_Text_Gary];
    [self.detailLab setFont:[UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(12)]];
    [self.detailLab setTextColor:kColor_Text_Black];
}


#pragma mark - set
- (void)setIndexPath:(NSIndexPath *)indexPath {
    _indexPath = indexPath;
    [_nameLab setText:@[KKLocalized(@"类型"),KKLocalized(@"金额"),KKLocalized(@"日期"),KKLocalized(@"备注")][indexPath.row]];
}

- (void)setModel:(BookDetailModel *)model {
    _model = model;
    if (_indexPath.row == 0) {
        [_detailLab setText:[model getTypeDesc]];
    } else if (_indexPath.row == 1) {
        [_detailLab setText:[model getPriceStr]];
    } else if (_indexPath.row == 2) {
        [_detailLab setText:[model getDateStr]];
    } else if (_indexPath.row == 3) {
        NSString *mark;
        if ((model.mark && model.mark.length != 0)) {
            mark = model.mark;
        }else{
            BKCModel *cmodel = [NSUserDefaults getCategoryModel:model.categoryId];
            mark = cmodel.name;
        }
        [_detailLab setText:mark];
    }
}


@end
