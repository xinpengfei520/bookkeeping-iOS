//
//  UITableViewHeaderFooterView+Extension.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/7/19.
//  Copyright © 2022 kk. All rights reserved.
//

#import "UITableViewHeaderFooterView+Extension.h"

@implementation UITableViewHeaderFooterView (Extension)

// 加载第一个nib
+ (instancetype)loadFirstNib:(CGRect)frame table:(UITableView *)table {
    UITableViewHeaderFooterView *cell = [self loadNib:0 frame:frame table:table];
    return cell;
}

// 加载最后一个nib
+ (instancetype)loadLastNib:(CGRect)frame table:(UITableView *)table {
    NSInteger index = [self getCells].count - 1;
    UITableViewHeaderFooterView *header = [self loadNib:index frame:frame table:table];
    [header initUI];
    return header;
}

// 从代码创建cell
+ (instancetype)loadCode:(CGRect)frame table:(UITableView *)table {
    NSString *name = NSStringFromClass(self);
    UITableViewHeaderFooterView *header = [table dequeueReusableHeaderFooterViewWithIdentifier:name];
    if (!header) {
        header = [[self alloc] initWithReuseIdentifier:name];
        header.frame = frame;
    }
    
    [header initUI];
    return header;
}

// 加载指定nib
+ (instancetype)loadNib:(NSInteger)index frame:(CGRect)frame table:(UITableView *)table {
    NSString *name = NSStringFromClass(self);
    UITableViewHeaderFooterView *header = [table dequeueReusableHeaderFooterViewWithIdentifier:name];
    if (!header) {
        header = [[NSBundle mainBundle] loadNibNamed:name owner:nil options:nil][index];
        header.frame = frame;
    }
    
    [header initUI];
    return header;
}

// 获取XIB中cell个数
+ (NSArray *)getCells {
    NSString *name = NSStringFromClass(self);
    return [[NSBundle mainBundle] loadNibNamed:name owner:nil options:nil];
}

// 初始化
- (void)initUI {
    
}

@end
