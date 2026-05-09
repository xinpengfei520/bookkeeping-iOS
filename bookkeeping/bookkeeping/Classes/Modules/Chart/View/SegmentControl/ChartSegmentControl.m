/**
 * 图表
 * @author 郑业强 2018-12-17 创建文件
 */

#import "ChartSegmentControl.h"

#pragma mark - 声明
@interface ChartSegmentControl()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *segConstraintL;

@end


#pragma mark - 实现
@implementation ChartSegmentControl


- (void)initUI {
    CGFloat height = 28;

    [self setBackgroundColor:kColor_Main_Color];

    // XIB 写死的 segments（周/月/年）。这里用 site-specific 直接设置，避免污染
    // KKEnglishTable 全局映射（@"月" 已被 HomeHeader 占用为 "Mo." 后缀）。
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
    
    [self.segConstraintL setConstant:countcoordinatesX(10)];
}


@end
