/**
 * 列表cell
 * @author 郑业强 2018-12-17 创建文件
 */

#import "HomeListCell.h"
#import "HomeListHeader.h"
#import "HomeListSubCell.h"
#import "HomeListEmpty.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface HomeListCell()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) HomeListEmpty *emptyView;

@end


#pragma mark - 实现
@implementation HomeListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self setBackgroundColor:[UIColor whiteColor]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    // 初始化表格
    [self table];
    
    // 初始化空视图
    _emptyView = [[HomeListEmpty alloc] init];
    [self.table addSubview:_emptyView];
    
    // 设置约束
    [_table mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
    
    [_emptyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
}


#pragma mark - set
- (void)setModels:(NSMutableArray<BookMonthModel *> *)models {
    _models = models;
    [self.table reloadData];
    [self.emptyView setHidden:models.count != 0];
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.models ? self.models.count : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.models[section].array.count;
}

/**
 * 关于 UITableViewCell 复用优化
 * HomeListSubCell 继承自 MGSwipeTableCell，而 MGSwipeTableCell 继承自系统的 UITableViewCell，UITableViewCell+Extension 分类中实现了复用逻辑，所以在这里可以不调用 dequeueReusableCellWithIdentifier
 * 只需要在 UITableView 初始化的时候注册 就可以了
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HomeListSubCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HomeListSubCell" forIndexPath:indexPath];
    cell.model = self.models[indexPath.section].array[indexPath.row];
    return cell;
}


#pragma mark - UITableViewDelegate
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    HomeListHeader *header = [HomeListHeader loadFirstNib:CGRectMake(0, 0, SCREEN_WIDTH, countcoordinatesX(30)) table:tableView];
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
    //BookDetailModel *model = self.models[indexPath.section].array[indexPath.row];
    [self routerEventWithName:HOME_CELL_CLICK data:indexPath];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    @weakify(self)
    UIContextualAction *delete = [UIContextualAction
        contextualActionWithStyle:UIContextualActionStyleDestructive
                            title:@"删除"
                          handler:^(UIContextualAction * _Nonnull action,
                                    __kindof UIView * _Nonnull sourceView,
                                    void (^ _Nonnull completion)(BOOL)) {
        @strongify(self)
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [self routerEventWithName:HOME_CELL_REMOVE data:cell];
        completion(YES);
    }];
    delete.backgroundColor = kColor_Red_Color;
    return [UISwipeActionsConfiguration configurationWithActions:@[delete]];
}

- (void)endRefresh {
    [self.table.kk_pullToRefreshHeader endRefreshing];
    [self.table.kk_loadMoreFooter endRefreshing];
}

- (void)refresh:(NSIndexPath *)indexPath {
    // 刷新单个 cell
    NSArray <NSIndexPath *> *indexPathArray = @[indexPath];
    [self.table reloadRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationAutomatic];
    // 刷新单个 section
    NSIndexSet *indexSet=[[NSIndexSet alloc] initWithIndex:indexPath.section];
    [self.table reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
}


- (UITableView *)table {
    if (!_table) {
        _table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        @weakify(self)
        // 下拉切换下月：自家 KKPullToRefreshHeader（替代 UIRefreshControl，支持
        // pulling/willRefresh/refreshing 三态文字 + 自定义触发距离）。
        KKPullToRefreshHeader *header = [KKPullToRefreshHeader headerWithRefreshingBlock:^{
            @strongify(self)
            [self routerEventWithName:HOME_TABLE_PULL data:nil];
        }];
        header.pullingTitle = @"下拉查看下月数据";
        header.willRefreshTitle = @"松开查看下月数据";
        header.refreshingTitle = @"查找数据中";
        _table.kk_pullToRefreshHeader = header;

        // 上拉切换上月
        KKLoadMoreFooter *footer = [KKLoadMoreFooter footerWithRefreshingBlock:^{
            @strongify(self)
            [self routerEventWithName:HOME_TABLE_UP data:nil];
        }];
        footer.pullingTitle = @"上拉查看上月数据";
        footer.willRefreshTitle = @"松开查看上月数据";
        footer.refreshingTitle = @"查找数据中";
        _table.kk_loadMoreFooter = footer;
        [_table lineHide];
        [_table lineAll];
        [_table setDelegate:self];
        [_table setDataSource:self];
        [_table setShowsVerticalScrollIndicator:false];
        [_table setSeparatorColor:kColor_Line_Color];
        [_table setBackgroundColor:kColor_White];
        [_table setTableHeaderView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 0.1)]];
        [_table registerClass:[HomeListSubCell class] forCellReuseIdentifier:@"HomeListSubCell"];
        [_table registerNib:[UINib nibWithNibName:@"HomeListHeader" bundle:nil] forHeaderFooterViewReuseIdentifier:@"HomeListHeader"];
        [self.contentView addSubview:_table];
    }
    return _table;
}

- (HomeListEmpty *)emptyView {
    if (!_emptyView) {
        _emptyView = [HomeListEmpty loadFirstNib:self.bounds];
        _emptyView.hidden = true;
        [self.table addSubview:_emptyView];
    }
    return _emptyView;
}


@end
