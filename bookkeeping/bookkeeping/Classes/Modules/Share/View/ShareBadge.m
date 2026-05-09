/**
 * 分享徽章
 * @author 郑业强 2018-12-21 创建文件
 */

#import "ShareBadge.h"


#pragma mark - 声明
@interface ShareBadge()

@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *nameLab;
@property (weak, nonatomic) IBOutlet UIImageView *badge;
@property (weak, nonatomic) IBOutlet UILabel *titleLab;
@property (weak, nonatomic) IBOutlet UILabel *detailLab;
@property (weak, nonatomic) IBOutlet UILabel *tipLab1;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraintH;

@end


#pragma mark - 实现
@implementation ShareBadge


- (void)initUI {
    [self.layer setMasksToBounds:YES];
    // XIB 静态文本：徽章模板上的标题 / 励志语 / 副标题
    [self.titleLab setText:KKLocalized(@"连续3天打卡徽章")];
    [self.detailLab setText:KKLocalized(@"成功是持续积累而成")];
    [self.tipLab1 setText:KKLocalized(@"爱记账，爱生活")];

    [self.nameLab setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.nameLab setTextColor:kColor_Text_Black];
    [self.titleLab setFont:[UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight]];
    [self.titleLab setTextColor:kColor_Text_Black];
    [self.detailLab setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.detailLab setTextColor:kColor_Text_Black];
    [self.tipLab1 setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.tipLab1 setTextColor:kColor_Text_Black];

    [self.bottomConstraintH setConstant:countcoordinatesX(70)];
}

@end
