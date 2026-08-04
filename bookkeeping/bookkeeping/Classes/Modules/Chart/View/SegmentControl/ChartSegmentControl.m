/**
 * 图表
 * @author 郑业强 2018-12-17 创建文件
 * 2026-08-04 XIB → 代码布局（Batch 6）
 */

#import "ChartSegmentControl.h"
#import <Masonry/Masonry.h>

#pragma mark - 实现
@implementation ChartSegmentControl

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

// 原 XIB：seg 居中，左右边距 15（运行时改 countcoordinatesX(10)），高度用固有尺寸
- (void)buildSubviews {
    _seg = [[UISegmentedControl alloc] initWithItems:@[@"周", @"月", @"年"]];
    _seg.selectedSegmentIndex = 0;
    [self addSubview:_seg];
    [_seg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.left.equalTo(self).offset(countcoordinatesX(10));
    }];
}

- (void)initUI {
    CGFloat height = 28;

    [self setBackgroundColor:kColor_Main_Color];

    // 周/月/年 site-specific 设置，避免污染 KKEnglishTable 全局映射
    // （@"月" 已被 HomeHeader 占用为 "Mo." 后缀）。
    BOOL isEn = [[KKI18n effectiveLanguageCode] isEqualToString:KKLanguageCodeEnglish];
    [self.seg setTitle:isEn ? @"Week"  : @"周" forSegmentAtIndex:0];
    [self.seg setTitle:isEn ? @"Month" : @"月" forSegmentAtIndex:1];
    [self.seg setTitle:isEn ? @"Year"  : @"年" forSegmentAtIndex:2];

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
    [self.seg.layer setCornerRadius:4];
    [self.seg.layer setMasksToBounds:YES];
    [self.seg.layer setBorderWidth:1];
    [self.seg.layer setBorderColor:kColor_Text_White.CGColor];
    [self.seg setTintColor:kColor_Text_White];
}


@end
