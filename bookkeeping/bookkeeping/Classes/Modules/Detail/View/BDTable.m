//
//  BDTable.m
//  bookkeeping
//
//  Created by 郑业强 on 2019/1/6.
//  Copyright © 2019年 kk. All rights reserved.
//

#import "BDTable.h"
#import "BDTableCell.h"
#import "BookDetailModel.h"

#pragma mark - 声明
@interface BDTable()<UITableViewDelegate, UITableViewDataSource>

@end


#pragma mark - 实现
@implementation BDTable


- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    if (self = [super initWithFrame:frame style:style]) {
        [self initUI];
    }
    return self;
}
- (void)initUI {
    [self setDelegate:self];
    [self setDataSource:self];
    [self lineHide];
    [self setSeparatorInset:UIEdgeInsetsMake(0, countcoordinatesX(15), 0, 0)];
    [self setSeparatorColor:kColor_Line_Color];
}


#pragma mark - set
- (void)setModel:(BookDetailModel *)model {
    _model = model;
    [self reloadData];
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!_model) {
        return 0;
    }
    // 外币记录多两行：原始金额 + 汇率，让用户能回溯当时是怎么算的
    return [_model isForeignCurrency] ? 6 : 4;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BDTableCell *cell = [BDTableCell loadCode:tableView];
    cell.indexPath = indexPath;
    cell.model = _model;
    return cell;
}


#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return countcoordinatesX(50);
}


@end
