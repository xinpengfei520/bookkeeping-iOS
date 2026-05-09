/**
 * 头视图
 * @author 郑业强 2019-01-09 创建文件
 */

#import "BillHeader.h"

#pragma mark - 声明
@interface BillHeader()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *labConstraintL;
@property (weak, nonatomic) IBOutlet UIView *line;
@property (weak, nonatomic) IBOutlet UIView *line1;
@property (weak, nonatomic) IBOutlet UILabel *lab1;
@property (weak, nonatomic) IBOutlet UILabel *lab2;
@property (weak, nonatomic) IBOutlet UILabel *lab3;
@property (weak, nonatomic) IBOutlet UILabel *money1Lab;
@property (weak, nonatomic) IBOutlet UILabel *money2Lab;
@property (weak, nonatomic) IBOutlet UILabel *money3Lab;
@property (weak, nonatomic) IBOutlet UIView *content;

@end


#pragma mark - 实现
@implementation BillHeader


- (void)initUI {
    [self.content setBackgroundColor:kColor_Main_Color];
    [self.line setBackgroundColor:kColor_Text_White];
    [self.line1 setBackgroundColor:[kColor_Text_White colorWithAlphaComponent:0.5]];
    [self.labConstraintL setConstant:countcoordinatesX(20)];

    // XIB 静态文本本地化（lab1=结余 lab2=收入 lab3=支出）；XIB 里另有 4 个未绑定
    // outlet 的 label 暂未处理，需要直接编辑 XIB 才能 localize。
    [self.lab1 setText:KKLocalized(@"结余")];
    [self.lab2 setText:KKLocalized(@"收入")];
    [self.lab3 setText:KKLocalized(@"支出")];
    
    for (id obj in self.subviews) {
        if ([obj isKindOfClass:[UILabel class]]) {
            UILabel *lab = obj;
            lab.font = [UIFont systemFontOfSize:AdjustFont(10)];
            lab.textColor = kColor_Text_Gary;
        }
    }
    
    [self.lab1 setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.lab1 setTextColor:kColor_Text_White];
    [self.lab2 setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.lab2 setTextColor:kColor_Text_White];
    [self.lab3 setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.lab3 setTextColor:kColor_Text_White];
    
    [self.money1Lab setFont:[UIFont systemFontOfSize:AdjustFont(30) weight:UIFontWeightLight]];
    [self.money1Lab setTextColor:kColor_Text_White];
    [self.money2Lab setFont:[UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight]];
    [self.money2Lab setTextColor:kColor_Text_White];
    [self.money3Lab setFont:[UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight]];
    [self.money3Lab setTextColor:kColor_Text_White];
}


#pragma mark - set
- (void)setIncome:(CGFloat)income {
    _income = income;
    NSString *incomeStr = [NSString stringWithFormat:@"%.2f", income];
    [self.money2Lab setAttributedText:[NSAttributedString createMath:incomeStr integer:[UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight] decimal:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight] color:kColor_Text_White]];
    
    NSString *money = [NSString stringWithFormat:@"%.2f", income - _pay];
    [self.money1Lab setAttributedText:[NSAttributedString createMath:money integer:[UIFont systemFontOfSize:AdjustFont(30) weight:UIFontWeightLight] decimal:[UIFont systemFontOfSize:AdjustFont(26) weight:UIFontWeightLight] color:kColor_Text_White]];
}

- (void)setPay:(CGFloat)pay {
    _pay = pay;
    NSString *payStr = [NSString stringWithFormat:@"%.2f", pay];
    [self.money3Lab setAttributedText:[NSAttributedString createMath:payStr integer:[UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight] decimal:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight] color:kColor_Text_White]];
    
    NSString *money = [NSString stringWithFormat:@"%.2f", _income - pay];
    [self.money1Lab setAttributedText:[NSAttributedString createMath:money integer:[UIFont systemFontOfSize:AdjustFont(30) weight:UIFontWeightLight] decimal:[UIFont systemFontOfSize:AdjustFont(26) weight:UIFontWeightLight] color:kColor_Text_White]];
}



@end
