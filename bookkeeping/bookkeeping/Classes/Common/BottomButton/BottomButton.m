/**
 * 分类
 * @author 郑业强 2018-12-17 创建文件
 */

#import "BottomButton.h"

#pragma mark - 声明
@interface BottomButton()

@end


#pragma mark - 实现
@implementation BottomButton


+ (instancetype)initWithFrame:(CGRect)frame {
    BottomButton *button = [BottomButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:frame];
    [button setTitleColor:kColor_Text_Black forState:UIControlStateNormal];
    [button setTitleColor:kColor_Text_Black forState:UIControlStateHighlighted];
    [button.titleLabel setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [button refreshBackgroundImages];
    [button shadowWithColor:kColor_Text_Gary offset:CGSizeMake(0, -3) opacity:0.1 radius:5];
    [button kk_addEventHandler:^(__kindof UIControl * _Nullable x) {
        [button routerEventWithName:CATEGORY_BTN_CLICK data:nil];
    } forControlEvents:UIControlEventTouchUpInside];
    return button;
}

// setBackgroundImage: 用 1×1 UIImage，dynamic color 在创建时就被快照成静态色，
// trait 切换时不会自动更新——必须监听 traitCollectionDidChange: 重新生成。
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self refreshBackgroundImages];
    }
}

- (void)refreshBackgroundImages {
    // light: 白底 + 浅灰按压；dark: 接近黑底 + 更暗按压
    [self setBackgroundImage:[UIColor createImageWithColor:[UIColor systemBackgroundColor]]
                    forState:UIControlStateNormal];
    [self setBackgroundImage:[UIColor createImageWithColor:[UIColor secondarySystemBackgroundColor]]
                    forState:UIControlStateHighlighted];
}

- (void)setName:(NSString *)name {
    _name = name;
    [self setTitle:name forState:UIControlStateNormal];
    [self setTitle:name forState:UIControlStateHighlighted];
}


@end
