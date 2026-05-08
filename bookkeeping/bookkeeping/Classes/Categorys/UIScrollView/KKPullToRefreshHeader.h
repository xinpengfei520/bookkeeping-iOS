//
//  KKPullToRefreshHeader.h
//  bookkeeping
//
//  Pull-down-to-trigger header. Symmetric to KKLoadMoreFooter and uses the
//  same 4-state machine (idle/pulling/willRefresh/refreshing). Replaces
//  UIRefreshControl when state-text feedback is needed (UIRefreshControl
//  exposes only a single static attributedTitle).
//
//  Usage:
//      scroll.kk_pullToRefreshHeader = [KKPullToRefreshHeader headerWithRefreshingBlock:^{
//          // refresh data / navigate / etc.
//      }];
//      ...
//      [scroll.kk_pullToRefreshHeader endRefreshing];
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKPullToRefreshHeader : UIView

+ (instancetype)headerWithRefreshingBlock:(void (^)(void))block;

@property (nonatomic, copy, nullable) NSString *pullingTitle;       // default: 下拉刷新
@property (nonatomic, copy, nullable) NSString *willRefreshTitle;   // default: 松开刷新
@property (nonatomic, copy, nullable) NSString *refreshingTitle;    // default: 加载中…

@property (nonatomic, assign, readonly) BOOL isRefreshing;

- (void)endRefreshing;

@end

#pragma mark - UIScrollView association

@interface UIScrollView (KKPullToRefreshHeader)
@property (nonatomic, strong, nullable) KKPullToRefreshHeader *kk_pullToRefreshHeader;
@end

NS_ASSUME_NONNULL_END
