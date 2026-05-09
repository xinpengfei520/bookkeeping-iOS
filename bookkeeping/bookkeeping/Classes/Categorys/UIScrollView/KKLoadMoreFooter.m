//
//  KKLoadMoreFooter.m
//  bookkeeping
//

#import "KKLoadMoreFooter.h"
#import <objc/runtime.h>

static const CGFloat kKKFooterHeight = 50.0;
static const CGFloat kKKFooterTriggerInset = 20.0;
static NSString * const kKKContentOffsetKeyPath = @"contentOffset";
static NSString * const kKKContentSizeKeyPath = @"contentSize";

typedef NS_ENUM(NSInteger, KKLoadMoreState) {
    KKLoadMoreStateIdle,
    KKLoadMoreStatePulling,
    KKLoadMoreStateWillRefresh,
    KKLoadMoreStateRefreshing,
    KKLoadMoreStateNoMore,
};

@interface KKLoadMoreFooter ()

@property (nonatomic, copy) void (^refreshingBlock)(void);
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIActivityIndicatorView *indicator;
@property (nonatomic, assign) KKLoadMoreState state;
// 检测从 dragging 到 not-dragging 的转换（松手时机）。
@property (nonatomic, assign) BOOL wasDragging;
@property (nonatomic, strong) NSDate *refreshingStartedAt;

@end

@implementation KKLoadMoreFooter

+ (instancetype)footerWithRefreshingBlock:(void (^)(void))block {
    KKLoadMoreFooter *footer = [[self alloc] initWithFrame:CGRectZero];
    footer.refreshingBlock = block;
    return footer;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _pullingTitle = KKLocalized(@"上拉加载更多");
        _willRefreshTitle = KKLocalized(@"松开加载更多");
        _refreshingTitle = KKLocalized(@"加载中…");
        _noMoreTitle = KKLocalized(@"没有更多了");
        _state = KKLoadMoreStateIdle;
        [self buildSubviews];
    }
    return self;
}

- (void)buildSubviews {
    self.backgroundColor = [UIColor clearColor];
    // 跟随 scroll 宽度自动 resize（防止初次 layout 时 width=0）
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    _titleLabel.font = [UIFont systemFontOfSize:13];
    _titleLabel.text = @"";   // idle 状态默认不显示文字
    [self addSubview:_titleLabel];

    _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    _indicator.hidesWhenStopped = YES;
    [self addSubview:_indicator];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // indicator 中央偏左避开文字（label 占满整宽 + textAlignment=center → 文字仍居中）
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
        [scroll addObserver:self forKeyPath:kKKContentSizeKeyPath options:NSKeyValueObservingOptionNew context:NULL];
        [self repositionInsideScrollView];
    }
}

- (void)detachFromScrollView {
    if (self.scrollView) {
        @try {
            [self.scrollView removeObserver:self forKeyPath:kKKContentOffsetKeyPath];
            [self.scrollView removeObserver:self forKeyPath:kKKContentSizeKeyPath];
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
    self.frame = CGRectMake(0, scroll.contentSize.height, width, kKKFooterHeight);
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if (object != self.scrollView) return;
    if ([keyPath isEqualToString:kKKContentSizeKeyPath]) {
        [self repositionInsideScrollView];
        return;
    }
    if (![keyPath isEqualToString:kKKContentOffsetKeyPath]) return;

    if (self.state == KKLoadMoreStateRefreshing || self.state == KKLoadMoreStateNoMore) return;

    UIScrollView *scroll = self.scrollView;
    CGFloat contentH = scroll.contentSize.height;
    CGFloat boundsH = scroll.bounds.size.height;
    CGFloat insetTop = scroll.adjustedContentInset.top;
    CGFloat insetBottom = scroll.adjustedContentInset.bottom;
    CGFloat offsetY = scroll.contentOffset.y;

    // 自然滚动的最大 offsetY —— 用户没主动拉拽时滚动条的下边界：
    //   * 内容超过一屏：滚到最底 = contentH + insetBottom - boundsH
    //   * 内容不足一屏：自然位置 = -insetTop（顶端对齐）
    CGFloat naturalMaxOffsetY = (contentH + insetTop + insetBottom > boundsH)
        ? (contentH + insetBottom - boundsH)
        : (-insetTop);
    CGFloat pullDistance = offsetY - naturalMaxOffsetY;
    CGFloat triggerThreshold = kKKFooterHeight + kKKFooterTriggerInset;

    BOOL nowDragging = scroll.isDragging;
    BOOL wasDragging = self.wasDragging;
    self.wasDragging = nowDragging;

    // 松手判定用"上一帧的 state"（同 KKPullToRefreshHeader）：松手瞬间
    // scroll 已经 bounce-back，pullDistance 回落，如果先算 newState 再判断
    // 会因为 state 被刷成 pulling 而错过触发。
    BOOL didReleaseFromWillRefresh = wasDragging && !nowDragging
                                  && self.state == KKLoadMoreStateWillRefresh;

    KKLoadMoreState newState;
    if (pullDistance <= 0) {
        newState = KKLoadMoreStateIdle;
    } else if (pullDistance < triggerThreshold) {
        newState = KKLoadMoreStatePulling;
    } else {
        newState = KKLoadMoreStateWillRefresh;
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
        case KKLoadMoreStateIdle:
            self.titleLabel.text = @"";    // 不显示
            break;
        case KKLoadMoreStatePulling:
            self.titleLabel.text = self.pullingTitle ?: @"";
            break;
        case KKLoadMoreStateWillRefresh:
            self.titleLabel.text = self.willRefreshTitle ?: @"";
            break;
        case KKLoadMoreStateRefreshing:
            self.titleLabel.text = self.refreshingTitle ?: @"";
            break;
        case KKLoadMoreStateNoMore:
            self.titleLabel.text = self.noMoreTitle ?: @"";
            break;
    }
}

- (void)beginRefreshing {
    if (self.state == KKLoadMoreStateRefreshing || self.state == KKLoadMoreStateNoMore) return;
    self.state = KKLoadMoreStateRefreshing;
    self.refreshingStartedAt = [NSDate date];
    [self refreshDisplayedTitle];
    [self.indicator startAnimating];
    if (self.refreshingBlock) {
        self.refreshingBlock();
    }
}

// 保证 spinner 至少持续 0.4 秒可见 —— 同步的 refreshingBlock + endRefresh
// 链路否则会在同一 runloop 完成，菊花根本没机会渲染。
static const NSTimeInterval kKKMinimumRefreshDuration = 0.4;

- (void)endRefreshing {
    if (self.state == KKLoadMoreStateNoMore) return;
    if (self.state != KKLoadMoreStateRefreshing) {
        // 不是 refreshing 状态时直接走原路径（idle / pulling / willRefresh）
        [self finishEndRefreshing];
        return;
    }
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
    if (self.state == KKLoadMoreStateNoMore) return;
    self.state = KKLoadMoreStateIdle;
    [self refreshDisplayedTitle];
    [self.indicator stopAnimating];
}

- (void)endRefreshingWithNoMoreData {
    self.state = KKLoadMoreStateNoMore;
    [self refreshDisplayedTitle];
    [self.indicator stopAnimating];
}

- (void)resetNoMoreData {
    if (self.state == KKLoadMoreStateNoMore) {
        self.state = KKLoadMoreStateIdle;
        [self refreshDisplayedTitle];
    }
}

- (BOOL)isRefreshing {
    return self.state == KKLoadMoreStateRefreshing;
}

@end

#pragma mark - UIScrollView association

@implementation UIScrollView (KKLoadMoreFooter)

- (void)setKk_loadMoreFooter:(KKLoadMoreFooter *)footer {
    KKLoadMoreFooter *existing = objc_getAssociatedObject(self, @selector(kk_loadMoreFooter));
    if (existing) {
        [existing removeFromSuperview];
    }
    objc_setAssociatedObject(self, @selector(kk_loadMoreFooter), footer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (footer && footer.superview != self) {
        [self addSubview:footer];
    }
}

- (KKLoadMoreFooter *)kk_loadMoreFooter {
    return objc_getAssociatedObject(self, @selector(kk_loadMoreFooter));
}

@end
