//
//  HomeAddBar.m
//  bookkeeping
//

#import "HomeAddBar.h"

static const CGFloat kPlusSize = 72;
static const CGFloat kPillHeight = 52;
static const CGFloat kSlideThreshold = 56;

#pragma mark - 声明
@interface HomeAddBar ()
@property (nonatomic, strong) UIView *pill;
@property (nonatomic, strong) UIButton *plusBtn;
@property (nonatomic, strong) UIControl *leftHit;
@property (nonatomic, strong) UIControl *rightHit;
@property (nonatomic, strong) UIView *leftCluster;
@property (nonatomic, strong) UIView *rightCluster;
@property (nonatomic, assign) CGPoint pressStart;
@property (nonatomic, assign) NSInteger slideSide;   // -1 / 0 / 1
@property (nonatomic, assign) BOOL expanded;
@property (nonatomic, assign) BOOL maskAnimating;
@end

#pragma mark - 实现
@implementation HomeAddBar

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self buildSubviews];
    }
    return self;
}

- (void)buildSubviews {
    _pill = [[UIView alloc] init];
    _pill.backgroundColor = KKDynamicColor(RGBA(28, 28, 30, 0.94), RGBA(20, 20, 22, 0.96));
    _pill.layer.cornerRadius = kPillHeight / 2;
    _pill.clipsToBounds = YES;
    [self addSubview:_pill];

    _leftCluster = [self clusterVoice];
    [_pill addSubview:_leftCluster];
    _rightCluster = [self clusterPhoto];
    [_pill addSubview:_rightCluster];

    _leftHit = [[UIControl alloc] init];
    _leftHit.userInteractionEnabled = NO;
    [self addSubview:_leftHit];

    _rightHit = [[UIControl alloc] init];
    _rightHit.userInteractionEnabled = NO;
    [self addSubview:_rightHit];

    // 默认只露中间 +，两侧等长按再展开
    _pill.alpha = 0;

    _plusBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_plusBtn setImage:[UIImage imageNamed:@"tabbar_add_n"] forState:UIControlStateNormal];
    _plusBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    _plusBtn.layer.shadowColor = kColor_Main_Color.CGColor;
    _plusBtn.layer.shadowOffset = CGSizeZero;
    _plusBtn.layer.shadowRadius = 10;
    _plusBtn.layer.shadowOpacity = 0.35;
    [_plusBtn addTarget:self action:@selector(plusTap) forControlEvents:UIControlEventTouchUpInside];
    UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(plusPress:)];
    press.minimumPressDuration = 0.28;
    press.allowableMovement = 200;
    [_plusBtn addGestureRecognizer:press];
    [self addSubview:_plusBtn];
}

- (UIView *)clusterVoice {
    UIView *box = [[UIView alloc] init];
    UILabel *lab = [[UILabel alloc] init];
    lab.text = KKLocalized(@"语音记账");
    lab.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    lab.textColor = [UIColor whiteColor];
    lab.tag = 11;
    [box addSubview:lab];

    UIImageView *mic = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_add_voice"]];
    mic.contentMode = UIViewContentModeScaleAspectFit;
    mic.tag = 12;
    [box addSubview:mic];

    UIImage *arrow = [[UIImage imageNamed:@"icon_add_arrow_left"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *arr = [[UIImageView alloc] initWithImage:arrow];
    arr.tintColor = RGBA(255, 255, 255, 0.92);
    arr.contentMode = UIViewContentModeScaleAspectFit;
    arr.tag = 13;
    [box addSubview:arr];
    return box;
}

- (UIView *)clusterPhoto {
    UIView *box = [[UIView alloc] init];
    UIImage *arrow = [[UIImage imageNamed:@"icon_add_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *arr = [[UIImageView alloc] initWithImage:arrow];
    arr.tintColor = RGBA(255, 255, 255, 0.92);
    arr.contentMode = UIViewContentModeScaleAspectFit;
    arr.tag = 21;
    [box addSubview:arr];

    UIImageView *pic = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_add_photo"]];
    pic.contentMode = UIViewContentModeScaleAspectFit;
    pic.tag = 22;
    [box addSubview:pic];

    UILabel *lab = [[UILabel alloc] init];
    lab.text = KKLocalized(@"图片识别");
    lab.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    lab.textColor = [UIColor whiteColor];
    lab.tag = 23;
    [box addSubview:lab];
    return box;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat pillW = w;
    CGFloat pillY = (h - kPillHeight) / 2;
    _pill.frame = CGRectMake(0, pillY, pillW, kPillHeight);
    if (!self.maskAnimating) {
        [self applyPillMaskExpanded:self.expanded];
    }

    CGFloat plusX = (w - kPlusSize) / 2;
    CGFloat plusY = (h - kPlusSize) / 2;
    _plusBtn.frame = CGRectMake(plusX, plusY, kPlusSize, kPlusSize);

    CGFloat sideW = plusX;
    _leftHit.frame = CGRectMake(0, 0, sideW, h);
    _rightHit.frame = CGRectMake(CGRectGetMaxX(_plusBtn.frame), 0, sideW, h);

    CGFloat icon = 22;
    CGFloat arrow = 16;
    CGFloat gap = 6;
    // 左：文案 + 麦 + 箭头，整体靠 + 左侧
    {
        UILabel *lab = [_leftCluster viewWithTag:11];
        UIView *mic = [_leftCluster viewWithTag:12];
        UIView *arr = [_leftCluster viewWithTag:13];
        [lab sizeToFit];
        CGFloat total = lab.bounds.size.width + gap + icon + gap + arrow;
        CGFloat x0 = MAX(14, sideW - total - 10);
        lab.frame = CGRectMake(0, (kPillHeight - lab.bounds.size.height) / 2, lab.bounds.size.width, lab.bounds.size.height);
        mic.frame = CGRectMake(lab.frame.size.width + gap, (kPillHeight - icon) / 2, icon, icon);
        arr.frame = CGRectMake(CGRectGetMaxX(mic.frame) + gap, (kPillHeight - arrow) / 2, arrow, arrow);
        _leftCluster.frame = CGRectMake(x0, 0, total, kPillHeight);
    }
    // 右：箭头 + 图 + 文案
    {
        UIView *arr = [_rightCluster viewWithTag:21];
        UIView *pic = [_rightCluster viewWithTag:22];
        UILabel *lab = [_rightCluster viewWithTag:23];
        [lab sizeToFit];
        CGFloat total = arrow + gap + icon + gap + lab.bounds.size.width;
        arr.frame = CGRectMake(0, (kPillHeight - arrow) / 2, arrow, arrow);
        pic.frame = CGRectMake(arrow + gap, (kPillHeight - icon) / 2, icon, icon);
        lab.frame = CGRectMake(CGRectGetMaxX(pic.frame) + gap, (kPillHeight - lab.bounds.size.height) / 2, lab.bounds.size.width, lab.bounds.size.height);
        CGFloat x0 = CGRectGetMaxX(_plusBtn.frame) - _pill.frame.origin.x + 10;
        if (x0 + total > pillW - 14) x0 = pillW - 14 - total;
        _rightCluster.frame = CGRectMake(x0, 0, total, kPillHeight);
    }
}

#pragma mark - action

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.expanded) return [super pointInside:point withEvent:event];
    return CGRectContainsPoint(CGRectInset(self.plusBtn.frame, -8, -8), point);
}

- (void)plusTap {
    if (self.tapBook) self.tapBook();
}

- (void)plusPress:(UILongPressGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateBegan) {
        self.pressStart = [g locationInView:self];
        self.slideSide = 0;
        [self setExpanded:YES animated:YES];
        [self applyHighlight:0];
    } else if (g.state == UIGestureRecognizerStateChanged) {
        CGPoint p = [g locationInView:self];
        CGFloat dx = p.x - self.pressStart.x;
        NSInteger side = 0;
        if (dx < -kSlideThreshold) side = -1;
        else if (dx > kSlideThreshold) side = 1;
        if (side != self.slideSide) {
            self.slideSide = side;
            [self applyHighlight:side];
        }
    } else if (g.state == UIGestureRecognizerStateEnded ||
               g.state == UIGestureRecognizerStateCancelled ||
               g.state == UIGestureRecognizerStateFailed) {
        NSInteger side = (g.state == UIGestureRecognizerStateEnded) ? self.slideSide : 0;
        self.slideSide = 0;
        self.leftCluster.alpha = 1;
        self.rightCluster.alpha = 1;
        self.leftCluster.transform = CGAffineTransformIdentity;
        self.rightCluster.transform = CGAffineTransformIdentity;
        [self setExpanded:NO animated:YES];
        if (side < 0 && self.tapVoice) self.tapVoice();
        else if (side > 0 && self.tapPhoto) self.tapPhoto();
        else if (self.slideEnded) self.slideEnded(side);
    }
}

- (CALayer *)pillMask {
    if (!self.pill.layer.mask) {
        CALayer *mask = [CALayer layer];
        mask.backgroundColor = [UIColor blackColor].CGColor;
        mask.cornerRadius = kPillHeight / 2.0;
        mask.anchorPoint = CGPointMake(0.5, 0.5);
        self.pill.layer.mask = mask;
    }
    return self.pill.layer.mask;
}

- (CGRect)maskBoundsExpanded:(BOOL)expanded {
    CGFloat w = self.pill.bounds.size.width;
    CGFloat h = self.pill.bounds.size.height;
    if (w < 1 || h < 1) {
        w = self.bounds.size.width;
        h = kPillHeight;
    }
    CGFloat mw = expanded ? w : MIN(kPlusSize, w);
    return CGRectMake(0, 0, mw, h);
}

- (void)applyPillMaskExpanded:(BOOL)expanded {
    CALayer *mask = [self pillMask];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    mask.bounds = [self maskBoundsExpanded:expanded];
    mask.position = CGPointMake(CGRectGetMidX(self.pill.bounds), CGRectGetMidY(self.pill.bounds));
    [CATransaction commit];
}

- (void)setExpanded:(BOOL)expanded animated:(BOOL)animated {
    _expanded = expanded;
    if (self.pill.bounds.size.width < 1) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }

    CALayer *mask = [self pillMask];
    CGRect toBounds = [self maskBoundsExpanded:expanded];
    CGPoint center = CGPointMake(CGRectGetMidX(self.pill.bounds), CGRectGetMidY(self.pill.bounds));

    if (!animated) {
        self.maskAnimating = NO;
        [self applyPillMaskExpanded:expanded];
        self.pill.alpha = expanded ? 1 : 0;
        return;
    }

    self.maskAnimating = YES;
    self.pill.alpha = 1;

    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"bounds"];
    anim.fromValue = [NSValue valueWithCGRect:mask.bounds];
    anim.toValue = [NSValue valueWithCGRect:toBounds];
    anim.duration = 0.24;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:
                           expanded ? kCAMediaTimingFunctionEaseOut : kCAMediaTimingFunctionEaseIn];
    mask.bounds = toBounds;
    mask.position = center;
    [mask addAnimation:anim forKey:@"bounds"];

    // 收到加号背后再隐去，避免半透明大胶囊看起来像往外散
    if (!expanded) {
        [UIView animateWithDuration:0.08 delay:0.16 options:UIViewAnimationOptionCurveLinear animations:^{
            self.pill.alpha = 0;
        } completion:^(BOOL finished) {
            self.maskAnimating = NO;
        }];
    } else {
        self.pill.alpha = 1;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.24 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.maskAnimating = NO;
        });
    }
}

- (void)applyHighlight:(NSInteger)side {
    [UIView animateWithDuration:0.15 animations:^{
        self.leftCluster.alpha = (side == 1) ? 0.35 : 1;
        self.rightCluster.alpha = (side == -1) ? 0.35 : 1;
        self.leftCluster.transform = (side == -1) ? CGAffineTransformMakeScale(1.06, 1.06) : CGAffineTransformIdentity;
        self.rightCluster.transform = (side == 1) ? CGAffineTransformMakeScale(1.06, 1.06) : CGAffineTransformIdentity;
    }];
}

@end
