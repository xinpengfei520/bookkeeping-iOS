//
//  KKPullToRefreshHeader.m
//  bookkeeping
//

#import "KKPullToRefreshHeader.h"
#import <objc/runtime.h>

static const CGFloat kKKHeaderHeight = 50.0;
static const CGFloat kKKHeaderTriggerInset = 20.0;
static NSString * const kKKContentOffsetKeyPath = @"contentOffset";

typedef NS_ENUM(NSInteger, KKPullToRefreshState) {
    KKPullToRefreshStateIdle,
    KKPullToRefreshStatePulling,
    KKPullToRefreshStateWillRefresh,
    KKPullToRefreshStateRefreshing,
};

@interface KKPullToRefreshHeader ()

@property (nonatomic, copy) void (^refreshingBlock)(void);
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIActivityIndicatorView *indicator;
@property (nonatomic, assign) KKPullToRefreshState state;
@property (nonatomic, assign) BOOL wasDragging;
@property (nonatomic, assign) CGFloat originalInsetTop;
@property (nonatomic, assign) BOOL insetAdjusted;
@property (nonatomic, strong) NSDate *refreshingStartedAt;

@end

@implementation KKPullToRefreshHeader

+ (instancetype)headerWithRefreshingBlock:(void (^)(void))block {
    KKPullToRefreshHeader *header = [[self alloc] initWithFrame:CGRectZero];
    header.refreshingBlock = block;
    return header;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _pullingTitle = @"下拉刷新";
        _willRefreshTitle = @"松开刷新";
        _refreshingTitle = @"加载中…";
        _state = KKPullToRefreshStateIdle;
        [self buildSubviews];
    }
    return self;
}

- (void)buildSubviews {
    self.backgroundColor = [UIColor clearColor];
    // 跟随 scroll 宽度自动 resize —— 否则 willMoveToSuperview 时 scroll.bounds.width
    // 可能还是 0，header 会一直保持 0 宽度而看不见。
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    _titleLabel.font = [UIFont systemFontOfSize:13];
    _titleLabel.text = @"";
    [self addSubview:_titleLabel];

    _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    _indicator.hidesWhenStopped = YES;
    [self addSubview:_indicator];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // indicator 永远在中央偏左（避开 label 文字），label 占满整宽且 textAlignment=center
    // → 文字仍居中、indicator 在文字左侧空白处转动，两者不重叠。
    self.titleLabel.frame = self.bounds;
    CGFloat midY = CGRectGetMidY(self.bounds);
    self.indicator.center = CGPointMake(self.bounds.size.width / 2.0 - 60, midY);
}

#pragma mark - Lifecycle attached to scroll view

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    [self detachFromScrollView];
    if ([newSuperview isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scroll = (UIScrollView *)newSuperview;
        self.scrollView = scroll;
        [scroll addObserver:self forKeyPath:kKKContentOffsetKeyPath options:NSKeyValueObservingOptionNew context:NULL];
        [self repositionInsideScrollView];
    }
}

- (void)detachFromScrollView {
    if (self.scrollView) {
        @try {
            [self.scrollView removeObserver:self forKeyPath:kKKContentOffsetKeyPath];
        } @catch (__unused NSException *e) {}
        self.scrollView = nil;
    }
}

- (void)dealloc {
    [self detachFromScrollView];
}

- (void)repositionInsideScrollView {
    UIScrollView *scroll = self.scrollView;
    if (!scroll) return;
    CGFloat width = scroll.bounds.size.width;
    self.frame = CGRectMake(0, -kKKHeaderHeight, width, kKKHeaderHeight);
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if (object != self.scrollView) return;
    if (![keyPath isEqualToString:kKKContentOffsetKeyPath]) return;

    if (self.state == KKPullToRefreshStateRefreshing) return;

    UIScrollView *scroll = self.scrollView;
    CGFloat insetTop = scroll.adjustedContentInset.top;
    CGFloat offsetY = scroll.contentOffset.y;
    // 用户向下拉拽的距离：自然顶边是 -insetTop，offsetY 比这小就是被拉下来了。
    CGFloat pullDistance = -insetTop - offsetY;
    CGFloat triggerThreshold = kKKHeaderHeight + kKKHeaderTriggerInset;

    BOOL nowDragging = scroll.isDragging;
    BOOL wasDragging = self.wasDragging;
    self.wasDragging = nowDragging;

    // 松手判定必须用"上一帧的 state" —— 用户松手瞬间 scroll 已经开始 bounce-back，
    // pullDistance 立即回落，如果在算完 newState 后再判断会因为 newState 已变为
    // pulling 而错过触发。
    BOOL didReleaseFromWillRefresh = wasDragging && !nowDragging
                                  && self.state == KKPullToRefreshStateWillRefresh;

    KKPullToRefreshState newState;
    if (pullDistance <= 0) {
        newState = KKPullToRefreshStateIdle;
    } else if (pullDistance < triggerThreshold) {
        newState = KKPullToRefreshStatePulling;
    } else {
        newState = KKPullToRefreshStateWillRefresh;
    }

    if (newState != self.state) {
        self.state = newState;
        [self refreshDisplayedTitle];
    }

    if (didReleaseFromWillRefresh) {
        [self beginRefreshing];
    }
}

- (void)refreshDisplayedTitle {
    switch (self.state) {
        case KKPullToRefreshStateIdle:
            self.titleLabel.text = @"";
            break;
        case KKPullToRefreshStatePulling:
            self.titleLabel.text = self.pullingTitle ?: @"";
            break;
        case KKPullToRefreshStateWillRefresh:
            self.titleLabel.text = self.willRefreshTitle ?: @"";
            break;
        case KKPullToRefreshStateRefreshing:
            self.titleLabel.text = self.refreshingTitle ?: @"";
            break;
    }
}

- (void)beginRefreshing {
    if (self.state == KKPullToRefreshStateRefreshing) return;
    self.state = KKPullToRefreshStateRefreshing;
    self.refreshingStartedAt = [NSDate date];
    [self refreshDisplayedTitle];
    [self.indicator startAnimating];

    // 调整 contentInset.top += headerHeight 让 header 一直可见（spinner 区域固定）。
    UIScrollView *scroll = self.scrollView;
    if (scroll && !self.insetAdjusted) {
        self.originalInsetTop = scroll.contentInset.top;
        UIEdgeInsets insets = scroll.contentInset;
        insets.top += kKKHeaderHeight;
        self.insetAdjusted = YES;
        [UIView animateWithDuration:0.25 animations:^{
            scroll.contentInset = insets;
        }];
    }

    if (self.refreshingBlock) {
        self.refreshingBlock();
    }
}

// 保证 spinner 至少持续 minimumDuration 让用户看得到 —— 否则同步的
// refreshingBlock + endRefresh 链路会在同一 runloop 完成，菊花根本没机会渲染。
static const NSTimeInterval kKKMinimumRefreshDuration = 0.4;

- (void)endRefreshing {
    if (self.state != KKPullToRefreshStateRefreshing) return;
    NSTimeInterval elapsed = self.refreshingStartedAt
        ? [[NSDate date] timeIntervalSinceDate:self.refreshingStartedAt]
        : kKKMinimumRefreshDuration;
    if (elapsed >= kKKMinimumRefreshDuration) {
        [self finishEndRefreshing];
    } else {
        NSTimeInterval delay = kKKMinimumRefreshDuration - elapsed;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [self finishEndRefreshing];
        });
    }
}

- (void)finishEndRefreshing {
    if (self.state != KKPullToRefreshStateRefreshing) return;

    UIScrollView *scroll = self.scrollView;
    if (scroll && self.insetAdjusted) {
        UIEdgeInsets insets = scroll.contentInset;
        insets.top -= kKKHeaderHeight;
        self.insetAdjusted = NO;
        [UIView animateWithDuration:0.25 animations:^{
            scroll.contentInset = insets;
        }];
    }

    self.state = KKPullToRefreshStateIdle;
    [self refreshDisplayedTitle];
    [self.indicator stopAnimating];
}

- (BOOL)isRefreshing {
    return self.state == KKPullToRefreshStateRefreshing;
}

@end

#pragma mark - UIScrollView association

@implementation UIScrollView (KKPullToRefreshHeader)

- (void)setKk_pullToRefreshHeader:(KKPullToRefreshHeader *)header {
    KKPullToRefreshHeader *existing = objc_getAssociatedObject(self, @selector(kk_pullToRefreshHeader));
    if (existing) {
        [existing removeFromSuperview];
    }
    objc_setAssociatedObject(self, @selector(kk_pullToRefreshHeader), header, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (header && header.superview != self) {
        [self addSubview:header];
    }
}

- (KKPullToRefreshHeader *)kk_pullToRefreshHeader {
    return objc_getAssociatedObject(self, @selector(kk_pullToRefreshHeader));
}

@end
