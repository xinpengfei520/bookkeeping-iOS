/**
 * 分类
 * @author 郑业强 2018-12-17 创建文件
 * 2026-08-04 XIB → 代码布局（Batch 8）
 */

#import "CAHeader.h"
#import <Masonry/Masonry.h>

#pragma mark - 实现
@implementation CAHeader

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

// 原 XIB：支出/收入 两段 seg 居中，左右边距 30
- (void)buildSubviews {
    _seg = [[UISegmentedControl alloc] initWithItems:@[@"支出", @"收入"]];
    _seg.selectedSegmentIndex = 0;
    [_seg addTarget:self action:@selector(segValueChange:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_seg];
    [_seg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.left.equalTo(self).offset(30);
    }];
}

- (void)initUI {
    CGFloat height = 30;
    [self setBackgroundColor:kColor_Main_Color];

    [self.seg setTitle:KKLocalized(@"支出") forSegmentAtIndex:0];
    [self.seg setTitle:KKLocalized(@"收入") forSegmentAtIndex:1];

    [self.seg setBackgroundColor:kColor_Main_Color];
    [self.seg setBackgroundImage:[UIColor createImageWithColor:kColor_Main_Color size:CGSizeMake(1, height)]
                        forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [self.seg setBackgroundImage:[UIColor createImageWithColor:kColor_Main_Dark_Color size:CGSizeMake(1, height)]
                        forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    [self.seg setBackgroundImage:[UIColor createImageWithColor:kColor_Text_White size:CGSizeMake(1, height)]
                        forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];

    NSDictionary *dic1 = @{NSForegroundColorAttributeName: kColor_Text_White};
    [self.seg setTitleTextAttributes:dic1 forState:UIControlStateNormal];
    NSDictionary *dic2 = @{NSForegroundColorAttributeName: kColor_Main_Color};
    [self.seg setTitleTextAttributes:dic2 forState:UIControlStateSelected];
    [self.seg.layer setCornerRadius:5];
    [self.seg.layer setMasksToBounds:YES];
    [self.seg.layer setBorderWidth:1];
    [self.seg.layer setBorderColor:kColor_Text_White.CGColor];
    [self.seg setTintColor:kColor_Text_White];
}


- (void)segValueChange:(UISegmentedControl *)sender {
    [self routerEventWithName:CATEGORY_SEG_CHANGE data:@(sender.selectedSegmentIndex)];
}


@end
