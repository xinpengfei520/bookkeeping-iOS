/**
 * 我的头视图
 * @author 郑业强 2018-12-16 创建文件
 */

#import "MineTableHeader.h"

#pragma mark - 声明
@interface MineTableHeader()

@property (weak, nonatomic) IBOutlet UIImageView *icon;     // 头像
@property (weak, nonatomic) IBOutlet UILabel *nameLab;      // 姓名
@property (weak, nonatomic) IBOutlet UIView *infoView;      // 个人信息
@property (weak, nonatomic) IBOutlet UIView *dayView;
@property (weak, nonatomic) IBOutlet UIView *numberView;
@property (weak, nonatomic) IBOutlet UILabel *dayLab;
@property (weak, nonatomic) IBOutlet UILabel *numberLab;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *iconConstraintW;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *infoConstraintT;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *numberConstraintT;

@end


#pragma mark - 实现
@implementation MineTableHeader


- (void)initUI {
    [self setBackgroundColor:kColor_Main_Color];
    [self createLabel:self];
    [self.infoView setClipsToBounds:false];
    [self.infoView setBackgroundColor:[UIColor clearColor]];
    [self.nameLab setFont:[UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight]];
    [self.nameLab setTextColor:kColor_Text_White];
    
    [self.infoConstraintT setConstant:StatusBarHeight + countcoordinatesX(40)];
    [self.numberConstraintT setConstant:countcoordinatesX(10)];
    [self.iconConstraintW setConstant:countcoordinatesX(70)];
    
    [self.icon.layer setCornerRadius:countcoordinatesX(56) / 2];
    [self.icon.layer setMasksToBounds:true];
    
    @weakify(self)
    // 头像
    [self.infoView addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
        @strongify(self)
        [self routerEventWithName:MINE_HEADER_ICON_CLICK data:nil];
    }];
    // 记账总天数
    [self.dayView addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
        @strongify(self)
        [self routerEventWithName:MINE_HEADER_DAY_CLICK data:nil];
    }];
    // 记账总笔数
    [self.numberView addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
        @strongify(self)
        [self routerEventWithName:MINE_HEADER_NUMBER_CLICK data:nil];
    }];
    
}
- (void)createLabel:(UIView *)view {
    for (UIView *subview in view.subviews) {
        [self createLabel:subview];
        if ([subview isKindOfClass:[UILabel class]]) {
            if (subview.tag == 10) {
                UILabel *lab = (UILabel *)subview;
                lab.font = [UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight];
                lab.textColor = kColor_Text_White;
            }
            else if (subview.tag == 11) {
                UILabel *lab = (UILabel *)subview;
                lab.font = [UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight];
                lab.textColor = kColor_Text_White;
            }
        }
    }
}


#pragma mark - set
- (void)setModel:(UserModel *)model {
    _model = model;
    // 未登录
    if (!model) {
        [_icon setImage:[UIImage imageNamed:@"default_header"]];
        [_nameLab setText:@"未登录"];
        [_dayLab setText:@"0"];
        [_numberLab setText:@"0"];
        return;
    }
    
    if (model.userAvatar) {
        [_icon sd_setImageWithURL:[NSURL URLWithString:model.userAvatar]];
    }
    else {
        [_icon setImage:[UIImage imageNamed:@"default_header"]];
    }
    [_nameLab setText:model.nickname];
    [_dayLab setText:model.bookDays];
    [_numberLab setText:model.bookCounts];
}


@end
