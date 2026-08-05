/**
 * 汇率 7 天走势 sparkline
 * 说明见 KKRateTrendView.h。CAShapeLayer 画线，layoutSubviews 里按当前尺寸重算路径。
 */

#import "KKRateTrendView.h"

@interface KKRateTrendView ()

@property (nonatomic, strong) CAShapeLayer *lineLayer;
@property (nonatomic, strong) CAShapeLayer *dotLayer;
@property (nonatomic, strong) UILabel *maxLab;      // 左上：区间最高
@property (nonatomic, strong) UILabel *minLab;      // 左下：区间最低
@property (nonatomic, strong) UILabel *startLab;    // 底部：起始日期
@property (nonatomic, strong) UILabel *endLab;      // 底部：结束日期
@property (nonatomic, strong) UILabel *placeholderLab;

@property (nonatomic, copy) NSArray<NSNumber *> *values;
@property (nonatomic, copy) NSArray<NSString *> *dates;

@end

@implementation KKRateTrendView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

- (void)buildSubviews {
    _lineLayer = [CAShapeLayer layer];
    _lineLayer.fillColor = UIColor.clearColor.CGColor;
    _lineLayer.lineWidth = 1.5;
    _lineLayer.lineJoin = kCALineJoinRound;
    _lineLayer.lineCap = kCALineCapRound;
    [self.layer addSublayer:_lineLayer];

    _dotLayer = [CAShapeLayer layer];
    _dotLayer.lineWidth = 0;
    [self.layer addSublayer:_dotLayer];

    UIFont *small = [UIFont systemFontOfSize:AdjustFont(9) weight:UIFontWeightLight];
    for (UILabel *lab in @[self.maxLab = [[UILabel alloc] init],
                           self.minLab = [[UILabel alloc] init],
                           self.startLab = [[UILabel alloc] init],
                           self.endLab = [[UILabel alloc] init]]) {
        lab.font = small;
        lab.textColor = kColor_Text_Gary;
        [self addSubview:lab];
    }
    _endLab.textAlignment = NSTextAlignmentRight;

    _placeholderLab = [[UILabel alloc] init];
    _placeholderLab.font = [UIFont systemFontOfSize:AdjustFont(11) weight:UIFontWeightLight];
    _placeholderLab.textColor = kColor_Text_Gary;
    _placeholderLab.textAlignment = NSTextAlignmentCenter;
    _placeholderLab.hidden = YES;
    [self addSubview:_placeholderLab];
}

#pragma mark - 状态

- (void)showLoading {
    [self showPlaceholder:KKLocalized(@"走势加载中…")];
}

- (void)showEmpty {
    [self showPlaceholder:KKLocalized(@"暂无走势数据")];
}

- (void)showPlaceholder:(NSString *)text {
    self.values = nil;
    self.dates = nil;
    self.placeholderLab.text = text;
    self.placeholderLab.hidden = NO;
    self.lineLayer.path = NULL;
    self.dotLayer.path = NULL;
    self.maxLab.text = self.minLab.text = self.startLab.text = self.endLab.text = @"";
    [self setNeedsLayout];
}

- (void)setValues:(NSArray<NSNumber *> *)values dates:(NSArray<NSString *> *)dates {
    if (values.count < 2 || values.count != dates.count) {
        [self showEmpty];
        return;
    }
    _values = [values copy];
    _dates = [dates copy];
    self.placeholderLab.hidden = YES;
    [self setNeedsLayout];
}

#pragma mark - 布局与绘制

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat padding = countcoordinatesX(15);
    self.placeholderLab.frame = self.bounds;
    self.maxLab.frame = CGRectMake(padding, 2, self.width - 2 * padding, 12);
    self.minLab.frame = CGRectMake(padding, self.height - 30, self.width - 2 * padding, 12);
    self.startLab.frame = CGRectMake(padding, self.height - 16, (self.width - 2 * padding) / 2, 12);
    self.endLab.frame = CGRectMake(self.width / 2, self.height - 16, self.width / 2 - padding, 12);

    if (self.values.count < 2) {
        return;
    }

    double minV = self.values.firstObject.doubleValue, maxV = minV;
    for (NSNumber *n in self.values) {
        minV = MIN(minV, n.doubleValue);
        maxV = MAX(maxV, n.doubleValue);
    }
    // 平线（周末回退导致 7 天同值很常见）也要能画：人为撑开一点纵向区间
    double span = maxV - minV;
    if (span < 1e-9) {
        span = MAX(maxV * 0.01, 0.000001);
        minV -= span / 2;
        maxV += span / 2;
    }

    self.maxLab.text = [NSString stringWithFormat:KKLocalized(@"高 %.6f"), maxV];
    self.minLab.text = [NSString stringWithFormat:KKLocalized(@"低 %.6f"), minV];
    self.startLab.text = self.dates.firstObject;
    self.endLab.text = self.dates.lastObject;

    // 绘图区：上留 16（高值标签）下留 34（低值 + 日期）
    CGFloat top = 16, bottom = 34;
    CGFloat plotH = self.height - top - bottom;
    CGFloat plotW = self.width - 2 * padding;

    UIBezierPath *line = [UIBezierPath bezierPath];
    UIBezierPath *dots = [UIBezierPath bezierPath];
    for (NSUInteger i = 0; i < self.values.count; i++) {
        CGFloat x = padding + plotW * i / (self.values.count - 1);
        CGFloat y = top + plotH * (1 - (self.values[i].doubleValue - minV) / (maxV - minV));
        if (i == 0) {
            [line moveToPoint:CGPointMake(x, y)];
        } else {
            [line addLineToPoint:CGPointMake(x, y)];
        }
        [dots appendPath:[UIBezierPath bezierPathWithArcCenter:CGPointMake(x, y)
                                                        radius:2 startAngle:0 endAngle:M_PI * 2 clockwise:YES]];
    }
    self.lineLayer.strokeColor = kColor_Main_Color.CGColor;
    self.dotLayer.fillColor = kColor_Main_Color.CGColor;
    self.lineLayer.path = line.CGPath;
    self.dotLayer.path = dots.CGPath;
}

// 深浅色切换时 CGColor 不会自动跟随，重设一次
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self setNeedsLayout];
}

@end
