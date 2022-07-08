//
//  BillTable.m
//  bookkeeping
//
//  Created by 郑业强 on 2019/1/9.
//  Copyright © 2019年 kk. All rights reserved.
//

#import "BillTable.h"
#import "BillTableCell.h"
#import "BillHeader.h"

#pragma mark - 声明
@interface BillTable()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) BillHeader *header;

@end


#pragma mark - 实现
@implementation BillTable


- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    if (self = [super initWithFrame:frame style:style]) {
        [self setDelegate:self];
        [self setDataSource:self];
        [self setBackgroundColor:kColor_BG];
        [self lineHide];
        [self lineAll];
        [self setSeparatorColor:kColor_BG];
        [self setShowsVerticalScrollIndicator:false];
    }
    return self;
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.models.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BillTableCell *cell = [BillTableCell loadFirstNib:tableView];
    cell.model = self.models[indexPath.row];
    return cell;
}


#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return countcoordinatesX(45);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 140;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [self header];
}


#pragma mark - set
- (void)setIncome:(CGFloat)income {
    _income = income;
    _header.income = income;
}

- (void)setPay:(CGFloat)pay {
    _pay = pay;
    _header.pay = pay;
}

- (void)setModels:(NSMutableArray *)models {
    _models = models;
    [self reloadData];
}


#pragma mark - get
- (BillHeader *)header {
    if (!_header) {
        _header = [BillHeader loadFirstNib:CGRectMake(0, 0, SCREEN_WIDTH, 120)];
    }
    return _header;
}


@end
