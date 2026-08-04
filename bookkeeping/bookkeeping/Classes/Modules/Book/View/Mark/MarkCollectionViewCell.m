//
//  MarkCollectionViewCell.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/7/22.
//  Copyright © 2022 kk. All rights reserved.
//  2026-08-04 XIB → 代码布局（Batch 8），注册方式改 registerClass
//

#import "MarkCollectionViewCell.h"
#import <Masonry/Masonry.h>

@interface MarkCollectionViewCell()

@property (nonatomic, strong) UILabel *markLabel;

@end

@implementation MarkCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

- (void)buildSubviews {
    _markLabel = [[UILabel alloc] init];
    _markLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:_markLabel];
    [_markLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
}

- (void)initUI {
    self.markLabel.font = [UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight];
    self.markLabel.textColor = kColor_Text_Black;
    self.markLabel.backgroundColor = kColor_Line_Color;
    [self.markLabel.layer setCornerRadius:4];
    [self.markLabel.layer setMasksToBounds:YES];
}

#pragma mark - set
- (void)setChoose:(BOOL)choose {
    _choose = choose;
    if (choose == YES) {
        _markLabel.textColor = kColor_Text_White;
        _markLabel.backgroundColor = kColor_Main_Color;
    } else {
        _markLabel.textColor = kColor_Text_Black;
        _markLabel.backgroundColor = kColor_Line_Color;
    }
}

- (void)setModel:(MarkModel *)model {
    _model = model;
    _markLabel.text = model.markName;
}

@end
