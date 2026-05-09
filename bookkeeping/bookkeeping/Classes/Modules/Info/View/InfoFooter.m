/**
 * 按钮
 * @author 郑业强 2018-12-22 创建文件
 */

#import "InfoFooter.h"

#pragma mark - 声明
@interface InfoFooter()

@property (weak, nonatomic) IBOutlet UIButton *nameBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *btnConstraintT;

@end


#pragma mark - 实现
@implementation InfoFooter


- (void)initUI {
    // XIB 里 button title 写死成"退出登录"，覆盖一下走 KKLocalized
    [self.nameBtn setTitle:KKLocalized(@"退出登录") forState:UIControlStateNormal];
    [self.nameBtn setTitle:KKLocalized(@"退出登录") forState:UIControlStateHighlighted];

    [self.nameBtn.titleLabel setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.nameBtn setTitleColor:kColor_Text_Red forState:UIControlStateNormal];
    [self.nameBtn setTitleColor:kColor_Text_Red forState:UIControlStateHighlighted];
    [self.nameBtn setBackgroundImage:[UIColor createImageWithColor:[UIColor systemBackgroundColor]] forState:UIControlStateNormal];
    [self.nameBtn setBackgroundImage:[UIColor createImageWithColor:kColor_BG] forState:UIControlStateHighlighted];

    [self.btnConstraintT setConstant:countcoordinatesX(10)];
}

// 退出登录
- (IBAction)quitClick:(id)sender {
    [self routerEventWithName:INFO_FOOTER_CLICK data:nil];
}


@end
