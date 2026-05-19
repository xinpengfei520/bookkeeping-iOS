/**
 * 按钮（code-only — converted from InfoFooter.xib）
 * @author 郑业强 2018-12-22 创建文件
 */

#import "InfoFooter.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface InfoFooter()

@property (nonatomic, strong) UIButton *nameBtn;

@end


#pragma mark - 实现
@implementation InfoFooter

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
        [self initUI];
    }
    return self;
}

- (void)buildSubviews {
    _nameBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_nameBtn addTarget:self action:@selector(quitClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_nameBtn];

    [_nameBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.top.equalTo(self).offset(countcoordinatesX(10));
    }];
}

- (void)initUI {
    [self.nameBtn setTitle:KKLocalized(@"退出登录") forState:UIControlStateNormal];
    [self.nameBtn setTitle:KKLocalized(@"退出登录") forState:UIControlStateHighlighted];

    [self.nameBtn.titleLabel setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.nameBtn setTitleColor:kColor_Text_Red forState:UIControlStateNormal];
    [self.nameBtn setTitleColor:kColor_Text_Red forState:UIControlStateHighlighted];
    [self.nameBtn setBackgroundImage:[UIColor createImageWithColor:[UIColor systemBackgroundColor]] forState:UIControlStateNormal];
    [self.nameBtn setBackgroundImage:[UIColor createImageWithColor:kColor_BG] forState:UIControlStateHighlighted];
}

// 退出登录
- (void)quitClick:(id)sender {
    [self routerEventWithName:INFO_FOOTER_CLICK data:nil];
}


@end
