//
//  KKLoadMoreFooter.h
//  bookkeeping
//
//  MJRefresh's mj_footer replacement. iOS has no system "pull up to load
//  more" API, so we ship a tiny one ourselves: a 50pt-tall footer view
//  pinned at the scroll view's content bottom, KVO-driven from contentOffset
//  to fire its block when the user pulls past a threshold.
//
//  Usage:
//      scroll.kk_loadMoreFooter = [KKLoadMoreFooter footerWithRefreshingBlock:^{
//          // load next page / navigate / etc.
//      }];
//      ...
//      [scroll.kk_loadMoreFooter endRefreshing];
//      [scroll.kk_loadMoreFooter endRefreshingWithNoMoreData];
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKLoadMoreFooter : UIView

+ (instancetype)footerWithRefreshingBlock:(void (^)(void))block;

@property (nonatomic, copy, nullable) NSString *idleTitle;        // default: 上拉加载更多
@property (nonatomic, copy, nullable) NSString *refreshingTitle;  // default: 加载中…
@property (nonatomic, copy, nullable) NSString *noMoreTitle;      // default: 没有更多了

@property (nonatomic, assign, readonly) BOOL isRefreshing;

- (void)endRefreshing;
- (void)endRefreshingWithNoMoreData;
- (void)resetNoMoreData;  // back to idle so the footer can re-fire

@end

#pragma mark - UIScrollView association

@interface UIScrollView (KKLoadMoreFooter)
@property (nonatomic, strong, nullable) KKLoadMoreFooter *kk_loadMoreFooter;
@end

NS_ASSUME_NONNULL_END
