/**
 * 头视图
 * @author 郑业强 2018-12-18 创建文件
 */

#import "HomeListHeader.h"

#pragma mark - 声明
@interface HomeListHeader()

@property (weak, nonatomic) IBOutlet UILabel *nameLab;
@property (weak, nonatomic) IBOutlet UILabel *detailLab;
@property (weak, nonatomic) IBOutlet UIView *line;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameConstraintL;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detaileConstraintR;

@end


#pragma mark - 实现
@implementation HomeListHeader

- (void)initUI {
    // XIB 里 backgroundColor 用了 systemColor="groupTableViewBackgroundColor"，
    // Xcode 在某些版本会烘焙成静态 sRGB 不再随 trait collection 翻 — 在代码里
    // 显式设置一个 dynamic provider 覆盖，确保深色模式下 header 也跟着翻。
    [self setBackgroundColor:[UIColor systemGroupedBackgroundColor]];

    [self.nameLab setFont:[UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(10)]];
    [self.nameLab setTextColor:kColor_Text_Gary];
    [self.detailLab setFont:[UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(10)]];
    [self.detailLab setTextColor:kColor_Text_Gary];
    [self.line setBackgroundColor:kColor_Line_Color];

    [self.nameConstraintL setConstant:countcoordinatesX(15)];
    [self.detaileConstraintR setConstant:countcoordinatesX(15)];
}


#pragma mark - set
- (void)setModel:(BookMonthModel *)model {
    _model = model;
    [_nameLab setText:[model getDateDescribe]];
    [_detailLab setText:[model getMoneyDescribe]];
}


@end
