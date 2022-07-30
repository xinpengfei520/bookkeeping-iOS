//
//  SearchListCell.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/12.
//  Copyright © 2022 kk. All rights reserved.
//

#import "SearchListCell.h"
#import "SearchListHeader.h"
#import "SearchListSubCell.h"

#pragma mark - 声明
@interface SearchListCell()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *table;

@end

@implementation SearchListCell

- (void)initUI {
    [self setBackgroundColor:[UIColor brownColor]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    [self table];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.table setFrame:self.contentView.bounds];
}


#pragma mark - set
- (void)setModels:(NSMutableArray<BookMonthModel *> *)models {
    _models = models;
    [self.table reloadData];
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.models ? self.models.count : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.models[section].array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SearchListSubCell *cell = [SearchListSubCell loadFirstNib:tableView];
    cell.model = self.models[indexPath.section].array[indexPath.row];
    return cell;
}


#pragma mark - UITableViewDelegate
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    SearchListHeader *header = [SearchListHeader loadFirstNib:CGRectMake(0, 0, SCREEN_WIDTH, countcoordinatesX(30))];
    header.model = self.models[section];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return countcoordinatesX(40);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return countcoordinatesX(50);
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, countcoordinatesX(5))];
    view.backgroundColor = kColor_White;
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return countcoordinatesX(5);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BookDetailModel *model = self.models[indexPath.section].array[indexPath.row];
    [self routerEventWithName:SEARCH_CELL_CLICK data:model];
}


#pragma mark - get
- (UITableView *)table {
    if (!_table) {
        _table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        [_table lineHide];
        [_table lineAll];
        [_table setDelegate:self];
        [_table setDataSource:self];
        [_table setShowsVerticalScrollIndicator:false];
        [_table setSeparatorColor:kColor_Line_Color];
        [_table setBackgroundColor:kColor_White];
        [_table setTableHeaderView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 0.1)]];
        [self.contentView addSubview:_table];
    }
    return _table;
}

@end
