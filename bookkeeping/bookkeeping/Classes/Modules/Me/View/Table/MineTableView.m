/**
 * 我的页面列表视图
 * @author 郑业强 2018-12-16 创建文件
 */

#import "MineTableView.h"
#import "MineTableCell.h"
#import "MineTableHeader.h"

#pragma mark - 声明
@interface MineTableView()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) MineTableHeader *header;
@property (nonatomic, strong) NSArray<NSArray<NSArray *> *> *datas;

@end


#pragma mark - 实现
@implementation MineTableView


+ (instancetype)initWithFrame:(CGRect)frame {
    MineTableView *table = [[MineTableView alloc] initWithFrame:frame style:UITableViewStyleGrouped];
    [table setDelegate:table];
    [table setDataSource:table];
    [table lineHide];
    [table lineAll];
    [table setTableHeaderView:table.header];
    [table setShowsVerticalScrollIndicator:NO];
    [table setShowsHorizontalScrollIndicator:NO];
    [table setBackgroundColor:kColor_BG];
    [table setContentInset:UIEdgeInsetsMake(0, 0, countcoordinatesX(50), 0)];
    [table setBackgroundView:({
        UIView *back = [[UIView alloc] initWithFrame:table.bounds];
        [back setBackgroundColor:kColor_BG];
        [back addSubview:({
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, table.header.height)];
            view.backgroundColor = kColor_Main_Color;
            view;
        })];
        back;
    })];
    return table;
}

#pragma mark - set
- (void)setModel:(UserModel *)model {
    _model = model;
    _header.model = model;
    [self reloadData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.datas[0].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datas[0][section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MineTableCell *cell = [MineTableCell loadFirstNib:tableView];
    cell.indexPath = indexPath;
    cell.nameLab.text = self.datas[0][indexPath.section][indexPath.row];
    cell.icon.image = [UIImage imageNamed:self.datas[1][indexPath.section][indexPath.row]];
    cell.status = [self.datas[2][indexPath.section][indexPath.row] integerValue];
    cell.detailLab.hidden = indexPath.section != 0;

    // 给区块 1 里面下标为 3 的 Item 开关赋值
    if (indexPath.section == 1) {
        if (indexPath.row == 3) {
            NSNumber *faceId = [NSUserDefaults objectForKey:PIN_SETTING_FACE_ID];
            [cell.sw setOn:[faceId boolValue]];
        }
    }
    return cell;
}


#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return countcoordinatesX(50);
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return countcoordinatesX(10);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [UIView new];
    view.backgroundColor = kColor_BG;
    return view;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self routerEventWithName:MINE_CELL_CLICK data:indexPath];
}


#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self routerEventWithName:MINE_DID_SCROLL data:scrollView];
}


#pragma mark - get
- (MineTableHeader *)header {
    if (!_header) {
        _header = [[MineTableHeader alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, countcoordinatesX(240))];
    }
    return _header;
}

- (NSArray<NSArray<NSArray *> *> *)datas {
    _datas = @[
        @[
            @[@"我的账单"],
            @[@"类别设置",@"定时提醒",@"面容解锁",@"导出数据"],
            @[@"邀请好友",@"意见反馈",@"帮助",@"关于"]
        ],
        @[
            @[@"mine_bill"],
            @[@"mine_category",@"mine_remind",@"mine_face_id",@"mine_export"],
            @[@"mine_invite",@"mine_feedback",@"mine_help",@"mine_about"]
        ],
        @[
            @[@(0)],
            @[@(0),@(0),@(1),@(0)],
            @[@(0),@(0),@(0),@(0)]
        ]
    ];
    
    return _datas;
}


@end
