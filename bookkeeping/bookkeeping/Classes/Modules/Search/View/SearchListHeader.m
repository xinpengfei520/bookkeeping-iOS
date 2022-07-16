//
//  SearchListHeader.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/12.
//  Copyright © 2022 kk. All rights reserved.
//

#import "SearchListHeader.h"

@interface SearchListHeader()

@property (weak, nonatomic) IBOutlet UILabel *nameLab;
@property (weak, nonatomic) IBOutlet UILabel *detailLab;
@property (weak, nonatomic) IBOutlet UIView *line;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameConstraintL;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detaileConstraintR;

@end

@implementation SearchListHeader

- (void)initUI {
    [self.nameLab setFont:[UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(10)]];
    [self.nameLab setTextColor:kColor_Text_Gary];
    [self.detailLab setFont:[UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(10)]];
    [self.detailLab setTextColor:kColor_Text_Gary];
    [self.line setBackgroundColor:kColor_Line_Color];
    
    [self.nameConstraintL setConstant:countcoordinatesX(15)];
    [self.detaileConstraintR setConstant:countcoordinatesX(15)];
}

- (void)setModel:(BookMonthModel *)model {
    _model = model;
    [_nameLab setText:[model getDateDescribe]];
    [_detailLab setText:[model getMoneyDescribe]];
}

@end
