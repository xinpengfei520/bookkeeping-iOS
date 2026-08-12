/**
 * 图表
 * @author 郑业强 2018-12-16 创建文件
 */

#import "ChartController.h"
#import "ChartNavigation.h"
#import "ChartSegmentControl.h"
#import "ChartDate.h"
#import "ChartTableView.h"
#import "ChartHUD.h"
#import "ChartTableCell.h"
#import "BookChartModel.h"

#pragma mark - 声明
@interface ChartController()

@property (nonatomic, strong) ChartNavigation *navigation;
@property (nonatomic, strong) ChartSegmentControl *segment;
@property (nonatomic, strong) ChartDate *chartDate;
@property (nonatomic, strong) ChartHUD *chartHUD;
@property (nonatomic, strong) ChartTableView *table;

@property (nonatomic, assign) NSInteger navigationIndex;
@property (nonatomic, assign) NSInteger segmentIndex;

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) BookChartModel *model;
@property (nonatomic, strong) BookDetailModel *minModel;
@property (nonatomic, strong) BookDetailModel *maxModel;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSDictionary<NSString *, NSInvocation *> *eventStrategy;

@end


#pragma mark - 实现
@implementation ChartController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.prefersNavigationBarHidden = YES;
    _navigationIndex = _navIndex;
    _queue = [[NSOperationQueue alloc]init];
    // 串行：updateDataWithAsync 与 updateDateRangeWithAsync 都读写 _minModel/_maxModel
    // 和 chartDate 的数据源，并发跑会互相踩（读路径提速后竞态窗口对齐过一次，见 ChartDate）
    _queue.maxConcurrentOperationCount = 1;
    [self setDate:[NSDate date]];
    [self navigation];
    [self segment];
    [self chartDate];
    [self table];
    [self chartHUD];
    [self setNavigationIndex:_navigationIndex];
    [self updateDateRangeWithAsync];
    [self monitorNotification];
    [self updateDataWithAsync];
}

// 监听通知
- (void)monitorNotification {
    @weakify(self)
    // 删除记账(接受图表页面子类别页面删除操作)
    [self kk_observeNotification:NOTIFICATION_BOOK_DELETE usingBlock:^(id x) {
        @strongify(self)
        [self setDate:[NSDate date]];
        [self updateDataWithAsync];
        [self updateDateRangeWithAsync];
    }];
    // 修改记账(接受图表页面子类别页面修改操作)
    [self kk_observeNotification:NOTIFICATION_BOOK_UPDATE usingBlock:^(id x) {
        @strongify(self)
        [self setDate:[NSDate date]];
        [self updateDataWithAsync];
        [self updateDateRangeWithAsync];
    }];
}

- (void)updateDateRangeWithAsync {
    @weakify(self)
    NSBlockOperation *operation = [[NSBlockOperation alloc]init];
    [operation addExecutionBlock:^{
        @strongify(self)
        [self updateDateRange];
        [self.chartDate setSegmentIndex:self.segmentIndex];
    }];
    [self.queue addOperation:operation];
    
}

// 更新时间范围
// 单趟遍历用 dateNumber（纯整数 y*10000+m*100+d）同时找最早/最晚记录。
// 旧实现：谓词过滤一趟 + @min.date / @max.date 各触发全量 .date 求值
// （每条记录新建 NSDateFormatter）+ 两趟补充谓词定位记录 —— 共 4 趟遍历外加
// formatter 风暴，2000 条时一次刷新要创建数千个 formatter。
- (void)updateDateRange {
    BOOL byCategory = (_cmodel != nil);
    NSInteger categoryId = _cmodel.categoryId;
    BOOL isIncome = (_navigationIndex == 1);

    NSMutableArray<BookDetailModel *> *bookArr = [NSUserDefaults getAllBookList];
    BookDetailModel *minModel = nil, *maxModel = nil;
    NSInteger minNumber = NSIntegerMax, maxNumber = NSIntegerMin;
    for (BookDetailModel *model in bookArr) {
        if (byCategory) {
            if (model.categoryId != categoryId) continue;
        } else if (isIncome ? (model.categoryId < 33) : (model.categoryId > 32)) {
            continue;
        }
        NSInteger number = model.dateNumber;
        if (number < minNumber) { minNumber = number; minModel = model; }
        if (number > maxNumber) { maxNumber = number; maxModel = model; }
    }
    _minModel = minModel;
    _maxModel = maxModel;
    
    [_chartDate setMinModel:_minModel maxModel:_maxModel];
}

- (void)updateDataWithAsync {
    @weakify(self)
    NSBlockOperation *operation = [[NSBlockOperation alloc]init];
    [operation addExecutionBlock:^{
        @strongify(self)
        NSMutableArray<BookDetailModel *> *list = [NSUserDefaults getAllBookList];
        BookChartModel *chartModel = [BookChartModel statisticalChart:self.segmentIndex isIncome:self.navigationIndex cmodel:self.cmodel date:self.date arrm:list];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setModel:chartModel];
        });
    }];
    [self.queue addOperation:operation];
}

#pragma mark - event
- (void)routerEventWithName:(NSString *)eventName data:(id)data {
    [self handleEventWithName:eventName data:data];
}

- (void)handleEventWithName:(NSString *)eventName data:(id)data {
    NSInvocation *invocation = self.eventStrategy[eventName];
    [invocation setArgument:&data atIndex:2];
    [invocation invoke];
    [super routerEventWithName:eventName data:data];
}

// 点击Cell
- (void)chartTableClick:(NSIndexPath *)indexPath {
    BookDetailModel *model = self.model.groupArr[indexPath.row];
    if (!_cmodel) {
        ChartController *vc = [[ChartController alloc] init];
        vc.cmodel = model;
        // 将选中的 segment 下标也传递过去
        vc.segmentIndex = _segmentIndex;
        vc.isBookDetail = true;
        [self.navigationController pushViewController:vc animated:true];
    } else {
        BookDetailController *vc = [[BookDetailController alloc] init];
        vc.model = model;
        [self.navigationController pushViewController:vc animated:true];
    }
}


#pragma mark - set
- (void)setModel:(BookChartModel *)model {
    _model = model;
    _table.isBookDetail = _isBookDetail;
    _table.model = model;
}

- (void)setNavigationIndex:(NSInteger)navigationIndex {
    _navigationIndex = navigationIndex;
    _navigation.navigationIndex = navigationIndex;
    _chartDate.navigationIndex = navigationIndex;
    _table.navigationIndex = navigationIndex;
}

- (void)setSegmentIndex:(NSInteger)segmentIndex {
    _segmentIndex = segmentIndex;
    _chartDate.segmentIndex = segmentIndex;
    _table.segmentIndex = segmentIndex;
}


#pragma mark - get
- (ChartNavigation *)navigation {
    if (!_navigation) {
        @weakify(self)
        _navigation = [ChartNavigation loadCode:CGRectMake(0, 0, SCREEN_WIDTH, NavigationBarHeight)];
        [_navigation setCmodel:_cmodel];
        [_navigation.button kk_addEventHandler:^(UIControl *button) {
            @strongify(self)
            [self.chartHUD show];
        } forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_navigation];
    }
    return _navigation;
}

- (ChartSegmentControl *)segment {
    if (!_segment) {
        @weakify(self)
        _segment = [ChartSegmentControl loadCode:CGRectMake(0, NavigationBarHeight, SCREEN_WIDTH, countcoordinatesX(50))];
        [_segment.seg kk_addEventHandler:^(UISegmentedControl *seg) {
            @strongify(self)
            // 空数据 / 列表尚未构建完成时 selectIndexs 还是空的，别越界
            NSInteger index = seg.selectedSegmentIndex;
            if (index < (NSInteger)self.chartDate.selectIndexs.count &&
                index < (NSInteger)self.chartDate.sModels.count) {
                NSIndexPath *indexPath = self.chartDate.selectIndexs[index];
                if (indexPath.row < (NSInteger)self.chartDate.sModels[index].count) {
                    ChartSubModel *model = self.chartDate.sModels[index][indexPath.row];
                    NSInteger month = model.month == -1 ? 1 : model.month;
                    NSInteger day = model.day == -1 ? 1 : model.day;
                    [self setDate:[NSDate dateWithYMD:[NSString stringWithFormat:@"%ld-%02ld-%02ld", model.year, month, day]]];
                }
            }
            [self setSegmentIndex:seg.selectedSegmentIndex];
            [self updateDataWithAsync];
        } forControlEvents:UIControlEventValueChanged];
        // 设置选中的 segment 下标
        _segment.seg.selectedSegmentIndex = _segmentIndex;
        [self.view addSubview:_segment];
    }
    return _segment;
}

- (ChartDate *)chartDate {
    if (!_chartDate) {
        @weakify(self)
        _chartDate = [ChartDate loadCode:CGRectMake(0, _segment.bottom, SCREEN_WIDTH, countcoordinatesX(45))];
        [_chartDate setComplete:^(ChartSubModel *model) {
            @strongify(self)
            NSInteger month = model.month == -1 ? 1 : model.month;
            NSInteger day = model.day == -1 ? 1 : model.day;
            NSString *str = [NSString stringWithFormat:@"%ld-%02ld-%02ld", model.year, month, day];
            [self setDate:[NSDate dateWithYMD:str]];
            [self updateDataWithAsync];
        }];
        [self.view addSubview:_chartDate];
    }
    return _chartDate;
}

- (ChartTableView *)table {
    if (!_table) {
        _table = [ChartTableView initWithFrame:({
            CGFloat top = self.chartDate.bottom;
            CGFloat height = SCREEN_HEIGHT - top;
            height -= self.navigationController.viewControllers.count == 1 ? TabbarHeight : 0;
            CGRectMake(0, top, SCREEN_WIDTH, height);
        })];
        [self.view addSubview:_table];
    }
    return _table;
}

- (ChartHUD *)chartHUD {
    if (!_chartHUD) {
        @weakify(self)
        _chartHUD = [ChartHUD loadCode:CGRectMake(0, _segment.bottom, SCREEN_WIDTH, SCREEN_HEIGHT - _segment.bottom - TabbarHeight)];
        [_chartHUD setIndex:_navigationIndex];
        [_chartHUD setComplete:^(NSInteger index) {
            @strongify(self)
            [self setNavigationIndex:index];
            [self updateDateRangeWithAsync];
            [self updateDataWithAsync];
        }];
        [self.view addSubview:_chartHUD];
    }
    return _chartHUD;
}

- (NSDictionary<NSString *, NSInvocation *> *)eventStrategy {
    if (!_eventStrategy) {
        _eventStrategy = @{
            CHART_TABLE_CLICK: [self createInvocationWithSelector:@selector(chartTableClick:)]
        };
    }
    return _eventStrategy;
}


@end
