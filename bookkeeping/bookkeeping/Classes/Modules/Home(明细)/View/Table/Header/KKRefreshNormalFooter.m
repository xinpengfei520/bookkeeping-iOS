//
//  KKRefreshNormalFooter.m
//  bookkeeping
//
//  Created by zhongke on 2018/12/28.
//  Copyright © 2018年 kk. All rights reserved.
//

#import "KKRefreshNormalFooter.h"

@implementation KKRefreshNormalFooter

+ (instancetype)footerWithRefreshingBlock:(MJRefreshComponentRefreshingBlock)refreshingBlock {
    KKRefreshNormalFooter *footer = [super footerWithRefreshingBlock:refreshingBlock];
    [footer setTitle:@"上拉查看上月数据" forState:MJRefreshStateIdle];
    [footer setTitle:@"送开可查看上月数据" forState:MJRefreshStatePulling];
    [footer setTitle:@"查找数据中" forState:MJRefreshStateRefreshing];
    [footer setTitle:@"" forState:MJRefreshStateWillRefresh];
    [footer.arrowView setHidden:YES];
    [footer.arrowView setAlpha:0];
    [footer.stateLabel setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    return footer;
}

@end
