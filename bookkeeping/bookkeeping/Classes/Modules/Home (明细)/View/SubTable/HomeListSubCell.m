/**
 * 列表Cell
 * @author 郑业强 2018-12-18 创建文件
 */

#import "HomeListSubCell.h"
#import "HOME_EVENT.h"

#pragma mark - 声明
@interface HomeListSubCell()

@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *nameLab;
@property (weak, nonatomic) IBOutlet UILabel *detailLab;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *iconConstraintL;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detailConstraintR;

@end


#pragma mark - 实现
@implementation HomeListSubCell


- (void)initUI {
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    [self.nameLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.nameLab setTextColor:kColor_Text_Black];
    [self.detailLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.detailLab setTextColor:kColor_Text_Black];
    
    [self.iconConstraintL setConstant:countcoordinatesX(15)];
    [self.detailConstraintR setConstant:countcoordinatesX(15)];
    _categoryList = [NSUserDefaults getCategoryModelList];
    
    @weakify(self)
    MGSwipeButton *btn = [MGSwipeButton buttonWithTitle:@"删除" backgroundColor:kColor_Red_Color];
    [btn.titleLabel setFont:[UIFont systemFontOfSize:AdjustFont(14)]];
    [btn setButtonWidth:countcoordinatesX(80)];
    [btn setCallback:^BOOL(MGSwipeTableCell *cell) {
        @strongify(self)
        [self routerEventWithName:HOME_CELL_REMOVE data:self];
        return NO;
    }];
    [self setRightButtons:@[btn]];
}



#pragma mark - 点击
// 删除
- (IBAction)actionClick:(UIButton *)sender {
    [self routerEventWithName:HOME_CELL_REMOVE data:self];
}


#pragma mark - set
- (void)setModel:(BookDetailModel *)model {
    _model = model;
    BKCModel *cmodel = [self getCategoryModel:model.categoryId];
    // 显示类别图表
    [_icon setImage:[UIImage imageNamed:cmodel.icon_l]];
    // 显示备注
    [_nameLab setText:model.mark];
    // 显示记账信息
    [_detailLab setText:cmodel.is_income == 0 ? [@(-model.price) description] : [@(model.price) description]];
}

- (BKCModel *) getCategoryModel:(NSInteger)categoryId{
    BKCModel *findModel;
    for (BKCModel *model in _categoryList) {
        if (model.Id == categoryId) {
            findModel = model;
            break;
        }
    }
    return findModel;
}

@end
