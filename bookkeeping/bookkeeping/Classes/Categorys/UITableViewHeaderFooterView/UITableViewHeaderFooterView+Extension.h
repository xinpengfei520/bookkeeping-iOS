//
//  UITableViewHeaderFooterView+Extension.h
//  bookkeeping
//
//  Created by PengfeiXin on 2022/7/19.
//  Copyright © 2022 kk. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITableViewHeaderFooterView (Extension)

/// 加载第一个NIB
+ (instancetype)loadFirstNib:(CGRect)frame table:(UITableView *)table;
/// 加载最后一个nib
+ (instancetype)loadLastNib:(CGRect)frame table:(UITableView *)table;
/// 从代码创建cell
+ (instancetype)loadCode:(CGRect)frame table:(UITableView *)table;
/// 加载指定xib
+ (instancetype)loadNib:(NSInteger)index frame:(CGRect)frame table:(UITableView *)table;
/// 初始化
- (void)initUI;

@end

NS_ASSUME_NONNULL_END
