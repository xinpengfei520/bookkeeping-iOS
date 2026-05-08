//
//  KKLoadMoreFooter.h
//  bookkeeping
//
//  Pull-up-to-trigger footer with a 4-state machine that mirrors MJRefresh:
//
//      idle        → 用户在自然位置，文字隐藏（footer 看起来不存在）
//      pulling     → 用户开始上拉，未到触发阈值，显示 pullingTitle
//      willRefresh → 用户上拉超过阈值，松开会触发，显示 willRefreshTitle
//      refreshing  → 已触发，refreshingBlock 已 fire，显示 refreshingTitle
//      noMore      → 终止状态，显示 noMoreTitle
//
//  触发条件：state == willRefresh 且用户从 dragging 转为 not-dragging（松手）。
//  这样比"offsetY 跨过阈值"严格——单纯 KVO race 或 reload 后的 offset 抖动
//  不会误触发。
//
//  Usage:
//      scroll.kk_loadMoreFooter = [KKLoadMoreFooter footerWithRefreshingBlock:^{
//          // load next page / navigate / etc.
//      }];
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKLoadMoreFooter : UIView

+ (instancetype)footerWithRefreshingBlock:(void (^)(void))block;

@property (nonatomic, copy, nullable) NSString *pullingTitle;       // default: 上拉加载更多
@property (nonatomic, copy, nullable) NSString *willRefreshTitle;   // default: 松开加载更多
@property (nonatomic, copy, nullable) NSString *refreshingTitle;    // default: 加载中…
@property (nonatomic, copy, nullable) NSString *noMoreTitle;        // default: 没有更多了

@property (nonatomic, assign, readonly) BOOL isRefreshing;

- (void)endRefreshing;
- (void)endRefreshingWithNoMoreData;
- (void)resetNoMoreData;

@end

#pragma mark - UIScrollView association

@interface UIScrollView (KKLoadMoreFooter)
@property (nonatomic, strong, nullable) KKLoadMoreFooter *kk_loadMoreFooter;
@end

NS_ASSUME_NONNULL_END
