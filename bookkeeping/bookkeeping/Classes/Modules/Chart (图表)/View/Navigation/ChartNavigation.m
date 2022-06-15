/**
 * 导航栏
 * @author 郑业强 2018-12-17 创建文件
 */

#import "ChartNavigation.h"

#pragma mark - 声明
@interface ChartNavigation()

@property (weak, nonatomic) IBOutlet UILabel *nameLab;
@property (weak, nonatomic) IBOutlet UIImageView *timeDown;
@property (weak, nonatomic) IBOutlet UIButton *incomeBtn;
@property (weak, nonatomic) IBOutlet UILabel *titleLab;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;

@end


#pragma mark - 实现
@implementation ChartNavigation


- (void)initUI {
    [self setBackgroundColor:kColor_Main_Color];
    [self.titleLab setFont:[UIFont systemFontOfSize:AdjustFont(14)]];
    [self.titleLab setTextColor:kColor_Text_White];
    [self.nameLab setTextColor:kColor_Text_White];
}


#pragma mark - 点击
- (IBAction)backClick:(UIButton *)sender {
    [self.viewController.navigationController popViewControllerAnimated:true];
}


#pragma mark - set
- (void)setNavigationIndex:(NSInteger)navigationIndex {
    _navigationIndex = navigationIndex;
    if (navigationIndex == 0) {
        _nameLab.text = @"支出";
    } else {
        _nameLab.text = @"收入";
    }
}

- (void)setCmodel:(BookDetailModel *)cmodel {
    _cmodel = cmodel;
    if (_cmodel) {
        _nameLab.hidden = true;
        _timeDown.hidden = true;
        _incomeBtn.hidden = true;
        _backBtn.hidden = false;
        _titleLab.hidden = false;
        BKCModel *category = [NSUserDefaults getCategoryModel:cmodel.categoryId];
        _titleLab.text = category.name;
    } else {
        _nameLab.hidden = false;
        _timeDown.hidden = false;
        _incomeBtn.hidden = false;
        _backBtn.hidden = false;
        _titleLab.hidden = true;
    }
}


@end
