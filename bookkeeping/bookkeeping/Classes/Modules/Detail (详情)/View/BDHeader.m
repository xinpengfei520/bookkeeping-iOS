//
//  BDHeader.m
//  bookkeeping
//
//  Created by 郑业强 on 2019/1/5.
//  Copyright © 2019年 kk. All rights reserved.
//

#import "BDHeader.h"

#pragma mark - 声明
@interface BDHeader()

@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *nameLab;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *iconConstraintW;

@end


#pragma mark - 实现
@implementation BDHeader


- (void)initUI {
    [self setBackgroundColor:kColor_Main_Color];
    [self.nameLab setFont:[UIFont systemFontOfSize:AdjustFont(12)]];
    [self.nameLab setTextColor:kColor_Text_White];
    [self.iconConstraintW setConstant:countcoordinatesX(60)];
}

#pragma mark - 点击
- (IBAction)backClick:(UIButton *)sender {
    [self.viewController.navigationController popViewControllerAnimated:true];
}


#pragma mark - set
- (void)setModel:(BookDetailModel *)model {
    _model = model;
    BKCModel *cmodel = [self getCategoryModel:model.categoryId];
    [_icon setImage:[UIImage imageNamed:cmodel.icon_l]];
    [_nameLab setText:cmodel.name];
}

- (BKCModel *) getCategoryModel:(NSInteger)categoryId{
    NSMutableArray<BKCModel *> *categoryList = [NSUserDefaults getCategoryModelList];
    BKCModel *findModel;
    for (BKCModel *model in categoryList) {
        if (model.Id == categoryId) {
            findModel = model;
            break;
        }
    }
    return findModel;
}

@end
