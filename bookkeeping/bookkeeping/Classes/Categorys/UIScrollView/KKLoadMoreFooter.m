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
    KKLoadMoreStateRefreshing,
    KKLoadMoreStateNoMore,
};

@interface KKLoadMoreFooter ()

@property (nonatomic, copy) void (^refreshingBlock)(void);
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIActivityIndicatorView *indicator;
@property (nonatomic, assign) KKLoadMoreState state;

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
        _idleTitle = @"上拉加载更多";
        _refreshingTitle = @"加载中…";
        _noMoreTitle = @"没有更多了";
        _state = KKLoadMoreStateIdle;
        [self buildSubviews];
    }
    return self;
}

- (void)buildSubviews {
    self.backgroundColor = [UIColor clearColor];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    _titleLabel.font = [UIFont systemFontOfSize:13];
    _titleLabel.text = _idleTitle;
    [self addSubview:_titleLabel];

    _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    _indicator.hidesWhenStopped = YES;
    [self addSubview:_indicator];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.titleLabel.frame = self.bounds;
    self.indicator.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
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

    if (self.state != KKLoadMoreStateIdle) return;

    UIScrollView *scroll = self.scrollView;
    CGFloat contentH = scroll.contentSize.height;
    CGFloat boundsH = scroll.bounds.size.height;
    CGFloat insetBottom = scroll.adjustedContentInset.bottom;
    CGFloat offsetY = scroll.contentOffset.y;
    // The offset at which the user has just exposed the footer's bottom edge
    CGFloat triggerOffset = contentH + insetBottom - boundsH + kKKFooterHeight + kKKFooterTriggerInset;
    if (contentH <= 0) return;     // empty content — don't fire
    if (offsetY < triggerOffset) return;
    [self beginRefreshing];
}

- (void)beginRefreshing {
    if (self.state != KKLoadMoreStateIdle) return;
    self.state = KKLoadMoreStateRefreshing;
    self.titleLabel.text = self.refreshingTitle;
    [self.indicator startAnimating];
    if (self.refreshingBlock) {
        self.refreshingBlock();
    }
}

- (void)endRefreshing {
    if (self.state == KKLoadMoreStateNoMore) return;   // do not clobber no-more
    self.state = KKLoadMoreStateIdle;
    self.titleLabel.text = self.idleTitle;
    [self.indicator stopAnimating];
}

- (void)endRefreshingWithNoMoreData {
    self.state = KKLoadMoreStateNoMore;
    self.titleLabel.text = self.noMoreTitle;
    [self.indicator stopAnimating];
}

- (void)resetNoMoreData {
    if (self.state == KKLoadMoreStateNoMore) {
        self.state = KKLoadMoreStateIdle;
        self.titleLabel.text = self.idleTitle;
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
