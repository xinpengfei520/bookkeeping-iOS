/**
 * 月份
 * @author 郑业强 2019-01
 */

#import "ContentView.h"


#pragma mark - 声明
@interface ContentView()

@property (weak, nonatomic) IBOutlet UILabel *monthLab;
@property (weak, nonatomic) IBOutlet UILabel *monthDescLab;
@property (weak, nonatomic) IBOutlet UILabel *descLab1;
@property (weak, nonatomic) IBOutlet UILabel *descLab2;
@property (weak, nonatomic) IBOutlet UILabel *descLab3;
@property (weak, nonatomic) IBOutlet UILabel *valueLab1;
@property (weak, nonatomic) IBOutlet UILabel *valueLab2;
@property (weak, nonatomic) IBOutlet UILabel *valueLab3;
@property (weak, nonatomic) IBOutlet UIImageView *icon;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *monthConstraintW;

@end


#pragma mark - 实现
@implementation ContentView


- (void)initUI {
    [self.monthLab setFont:[UIFont systemFontOfSize:AdjustFont(16)]];
    [self.monthLab setTextColor:kColor_Text_Black];
    [self.monthDescLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.monthDescLab setTextColor:kColor_Text_Black];
    
    [self.descLab1 setFont:[UIFont systemFontOfSize:AdjustFont(8) weight:UIFontWeightLight]];
    [self.descLab1 setTextColor:kColor_Text_Black];
    [self.descLab2 setFont:[UIFont systemFontOfSize:AdjustFont(8) weight:UIFontWeightLight]];
    [self.descLab2 setTextColor:kColor_Text_Black];
    [self.descLab3 setFont:[UIFont systemFontOfSize:AdjustFont(8) weight:UIFontWeightLight]];
    [self.descLab3 setTextColor:kColor_Text_Black];
    
    [self.bookBtn setTitle:@"记一笔" forState:UIControlStateNormal];
    [self.bookBtn.layer setCornerRadius:3];
    [self.bookBtn.layer setMasksToBounds:true];
    [self.bookBtn setBackgroundColor:kColor_Main_Color];
    [self.bookBtn setBackgroundImage:[UIColor createImageWithColor:kColor_Main_Color] forState:UIControlStateNormal];
    [self.bookBtn setTitleColor:kColor_Text_White forState:UIControlStateNormal];
    [self.bookBtn setBackgroundImage:[UIColor createImageWithColor:kColor_Main_Dark_Color] forState:UIControlStateHighlighted];
    [self.bookBtn.titleLabel setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    
    [self.icon setBackgroundColor:kColor_Text_Gary];
    
    [self.valueLab1 setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.valueLab1 setTextColor:kColor_Text_Black];
    [self.valueLab2 setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.valueLab2 setTextColor:kColor_Text_Black];
    [self.valueLab3 setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.valueLab3 setTextColor:kColor_Text_Black];
    
    // 月份
    NSDate *date = [NSDate date];
    NSString *month = [@(date.month) description];
    [_monthLab setText:month];
    CGSize size = [month sizeWithAttributes:@{NSFontAttributeName:_monthLab.font}];
    if (size.width > _monthLab.bounds.size.width) {
        [_monthLab setAdjustsFontSizeToFitWidth:YES];
    }
    [_monthConstraintW setConstant:size.width];
    
    // 数据
    NSMutableArray<BookMonthModel *> *monthModels = [BookMonthModel statisticalMonthWithYear:date.year month:date.month];
    NSMutableArray<BookDetailModel *> *arrm = [NSMutableArray array];
    for (BookMonthModel *month in monthModels) {
        [arrm addObjectsFromArray:month.array];
    }

    // 支出
    NSMutableArray<BookDetailModel *> *pay = [NSMutableArray kk_filteredArrayUsingStringFormat:@"categoryId <= 32" array:arrm];
    CGFloat payPrice = [[pay valueForKeyPath:@"@sum.price.floatValue"] floatValue];

    // 收入
    NSMutableArray<BookDetailModel *> *income = [NSMutableArray kk_filteredArrayUsingStringFormat:@"categoryId >= 33" array:arrm];
    CGFloat incomePrice = [[income valueForKeyPath:@"@sum.price.floatValue"] floatValue];
    NSLog(@"incomePrice: %.2f,payPrice: %.2f,balance: %.2f",incomePrice,payPrice,(incomePrice - payPrice));

    [_valueLab1 setText:[self getPriceStr:incomePrice]];
    [_valueLab2 setText:[self getPriceStr:payPrice]];
    [_valueLab3 setText:[self getPriceStr:(incomePrice - payPrice)]];
}

-(NSString *)getPriceStr:(CGFloat)price{
    // 如果没有小数
    if (fmodf(price, 1)==0) {
        return [NSString stringWithFormat:@"%.0f",price];
        // 如果有一位小数
    } else if (fmodf(price*10, 1)==0) {
        return [NSString stringWithFormat:@"%.1f",price];
        // 如果有两位小数
    } else {
        return [NSString stringWithFormat:@"%.2f",price];
    }
}

@end
