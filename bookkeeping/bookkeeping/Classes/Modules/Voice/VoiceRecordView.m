//
//  VoiceRecordView.m
//  bookkeeping
//

#import "VoiceRecordView.h"

static const NSInteger kBarCount = 7;
static const CGFloat kBarMinHeight = 6;
static const CGFloat kBarMaxHeight = 34;

#pragma mark - 声明
@interface VoiceRecordView ()

@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) NSArray<UIView *> *bars;

@end

#pragma mark - 实现
@implementation VoiceRecordView

+ (instancetype)showInView:(UIView *)view {
    VoiceRecordView *overlay = [[VoiceRecordView alloc] initWithFrame:view.bounds];
    [view addSubview:overlay];
    overlay.card.alpha = 0;
    overlay.card.transform = CGAffineTransformMakeScale(0.9, 0.9);
    [UIView animateWithDuration:0.18 animations:^{
        overlay.card.alpha = 1;
        overlay.card.transform = CGAffineTransformIdentity;
    }];
    return overlay;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // 浮层本身不拦截触摸 —— 长按手势还在 + 号上持续跟踪
        self.userInteractionEnabled = NO;
        [self buildSubviews];
    }
    return self;
}

- (void)buildSubviews {
    CGFloat cardW = countcoordinatesX(260);
    CGFloat cardH = countcoordinatesX(150);
    _card = [[UIView alloc] initWithFrame:CGRectMake((self.width - cardW) / 2, (self.height - cardH) / 2 - countcoordinatesX(70), cardW, cardH)];
    _card.backgroundColor = RGBA(30, 30, 30, 0.92);
    _card.layer.cornerRadius = 14;
    [self addSubview:_card];

    _textLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 14, cardW - 28, countcoordinatesX(58))];
    _textLabel.font = [UIFont systemFontOfSize:15];
    _textLabel.textColor = [UIColor whiteColor];
    _textLabel.textAlignment = NSTextAlignmentCenter;
    _textLabel.numberOfLines = 2;
    _textLabel.text = KKLocalized(@"请说吧，我在听…");
    [_card addSubview:_textLabel];

    // 波形条
    CGFloat barW = 4, gap = 8;
    CGFloat totalW = kBarCount * barW + (kBarCount - 1) * gap;
    CGFloat barX = (cardW - totalW) / 2;
    CGFloat barCenterY = _textLabel.bottom + countcoordinatesX(24);
    NSMutableArray *bars = [NSMutableArray array];
    for (NSInteger i = 0; i < kBarCount; i++) {
        UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(barX + i * (barW + gap), barCenterY - kBarMinHeight / 2, barW, kBarMinHeight)];
        bar.backgroundColor = kColor_Main_Color;
        bar.layer.cornerRadius = barW / 2;
        [_card addSubview:bar];
        [bars addObject:bar];
    }
    _bars = bars;

    _hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, cardH - countcoordinatesX(30), cardW - 28, countcoordinatesX(20))];
    _hintLabel.font = [UIFont systemFontOfSize:12];
    _hintLabel.textColor = RGBA(255, 255, 255, 0.6);
    _hintLabel.textAlignment = NSTextAlignmentCenter;
    _hintLabel.text = KKLocalized(@"松开结束，上滑取消");
    [_card addSubview:_hintLabel];
}

#pragma mark - set

- (void)updateText:(NSString *)text {
    if (text.length) _textLabel.text = text;
}

- (void)updateLevel:(float)level {
    // 中间高两边低的包络，加一点随机让波形活起来
    CGFloat centerY = _bars.firstObject.center.y;
    [UIView animateWithDuration:0.08 delay:0 options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState animations:^{
        for (NSInteger i = 0; i < (NSInteger)self.bars.count; i++) {
            CGFloat envelope = 1.0 - fabs(i - (kBarCount - 1) / 2.0) / kBarCount;
            CGFloat jitter = 0.7 + (arc4random_uniform(60)) / 100.0;
            CGFloat h = kBarMinHeight + (kBarMaxHeight - kBarMinHeight) * MIN(1.0, level * envelope * jitter * 1.6);
            UIView *bar = self.bars[i];
            bar.frame = CGRectMake(bar.frame.origin.x, centerY - h / 2, bar.frame.size.width, h);
        }
    } completion:nil];
}

- (void)setCancelState:(BOOL)cancelState {
    _hintLabel.text = cancelState ? KKLocalized(@"松开取消") : KKLocalized(@"松开结束，上滑取消");
    _hintLabel.textColor = cancelState ? kColor_Text_Red : RGBA(255, 255, 255, 0.6);
    _card.layer.borderWidth = cancelState ? 1.5 : 0;
    _card.layer.borderColor = kColor_Text_Red.CGColor;
}

- (void)showRecognizing {
    _hintLabel.text = KKLocalized(@"识别中…");
    _hintLabel.textColor = RGBA(255, 255, 255, 0.6);
    _card.layer.borderWidth = 0;
    for (UIView *bar in _bars) {
        CGRect f = bar.frame;
        bar.frame = CGRectMake(f.origin.x, bar.center.y - kBarMinHeight / 2, f.size.width, kBarMinHeight);
    }
}

- (void)dismiss {
    [UIView animateWithDuration:0.15 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end
