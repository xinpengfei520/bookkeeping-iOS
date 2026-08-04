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
// 行文案在 setModel: 里一起刷 —— 外币记录会在"金额"后面插入两行，
// 光看 indexPath 判断不出该显示什么。
- (void)setIndexPath:(NSIndexPath *)indexPath {
    _indexPath = indexPath;
}

- (void)setModel:(BookDetailModel *)model {
    _model = model;

    BOOL foreign = [model isForeignCurrency];
    // 外币：类型 / 入账金额(人民币) / 原始金额 / 汇率 / 日期 / 备注
    // 人民币：类型 / 金额 / 日期 / 备注（与改造前完全一致）
    NSArray<NSString *> *names = foreign
        ? @[KKLocalized(@"类型"), KKLocalized(@"入账金额"), KKLocalized(@"原始金额"), KKLocalized(@"汇率"), KKLocalized(@"日期"), KKLocalized(@"备注")]
        : @[KKLocalized(@"类型"), KKLocalized(@"金额"), KKLocalized(@"日期"), KKLocalized(@"备注")];

    NSMutableArray<NSString *> *details = [NSMutableArray array];
    [details addObject:[model getTypeDesc] ?: @""];
    [details addObject:foreign ? [NSString stringWithFormat:@"¥%@", [KKCurrency formatAmount:model.price]] : ([model getPriceStr] ?: @"")];
    if (foreign) {
        [details addObject:[model getOriginalPriceStr] ?: @""];
        [details addObject:[model getExchangeRateStr] ?: @""];
    }
    [details addObject:[model getDateStr] ?: @""];
    [details addObject:({
        NSString *mark;
        if ((model.mark && model.mark.length != 0)) {
            mark = model.mark;
        } else {
            BKCModel *cmodel = [NSUserDefaults getCategoryModel:model.categoryId];
            mark = cmodel.name;
        }
        mark ?: @"";
    })];

    NSInteger row = _indexPath.row;
    if (row < 0 || row >= (NSInteger)names.count) {
        return;
    }
    [_nameLab setText:names[row]];
    [_detailLab setText:details[row]];
}


@end
