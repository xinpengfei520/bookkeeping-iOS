/**
 * 列表cell
 * @author 郑业强 2018-12-17 创建文件
 */

#import "HomeListCell.h"
#import "KKRefreshNormalHeader.h"
#import "KKRefreshNormalFooter.h"
#import "HomeListHeader.h"
#import "HomeListSubCell.h"
#import "HomeListEmpty.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface HomeListCell()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) KKRefreshNormalHeader *header;
@property (nonatomic, strong) KKRefreshNormalFooter *footer;
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

- (void)endRefresh {
    [self.table.mj_header endRefreshing];
    [self.table.mj_footer endRefreshing];
}

- (void)refresh:(NSIndexPath *)indexPath {
    // 刷新单个 cell
    NSArray <NSIndexPath *> *indexPathArray = @[indexPath];
    [self.table reloadRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationAutomatic];
    // 刷新单个 section
    NSIndexSet *indexSet=[[NSIndexSet alloc] initWithIndex:indexPath.section];
    [self.table reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - get
- (KKRefreshNormalHeader *)header {
    if (!_header) {
        __weak typeof(self) weak = self;
        _header = [KKRefreshNormalHeader headerWithRefreshingBlock:^{
            [weak routerEventWithName:HOME_TABLE_PULL data:nil];
        }];
    }
    return _header;
}

- (KKRefreshNormalFooter *)footer {
    if (!_footer) {
        __weak typeof(self) weak = self;
        _footer = [KKRefreshNormalFooter footerWithRefreshingBlock:^{
            [weak routerEventWithName:HOME_TABLE_UP data:nil];
        }];
    }
    return _footer;
}

- (UITableView *)table {
    if (!_table) {
        _table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        [_table setMj_header:self.header];
        [_table setMj_footer:self.footer];
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
