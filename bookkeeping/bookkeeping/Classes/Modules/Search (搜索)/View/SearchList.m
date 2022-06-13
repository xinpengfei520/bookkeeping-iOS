//
//  SearchList.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/12.
//  Copyright © 2022 kk. All rights reserved.
//

#import "SearchList.h"
#import "SearchListCell.h"

@interface SearchList()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *table;

@end

@implementation SearchList

- (void)initUI {
    [self setBackgroundColor:kColor_BG];
    [self table];
}

- (void)setModels:(NSMutableArray<BookMonthModel *> *)models {
    _models = models;
    NSIndexPath *index = [NSIndexPath indexPathForRow:0 inSection:0];
    SearchListCell *cell = [self.table cellForRowAtIndexPath:index];
    cell.models = models;
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SearchListCell *cell = [SearchListCell loadCode:tableView];
    return cell;
}


#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}


#pragma mark - get
- (UITableView *)table {
    if (!_table) {
        _table = [[UITableView alloc] initWithFrame:self.bounds style:UITableViewStylePlain];
        [_table setDelegate:self];
        [_table setDataSource:self];
        [_table setPagingEnabled:NO];
        [_table lineHide];
        [_table setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        [_table setShowsVerticalScrollIndicator:NO];
        [_table setScrollEnabled:NO];
        [self addSubview:_table];
    }
    return _table;
}

@end
