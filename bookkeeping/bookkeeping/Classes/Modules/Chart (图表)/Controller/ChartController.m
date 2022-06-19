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
#import "CHART_EVENT.h"
#import "LOGIN_NOTIFICATION.h"
#import "BookDetailController.h"
#import "UIViewController+HBD.h"
#import "BookChartModel.h"

#pragma mark - 声明
@interface ChartController()

@property (nonatomic, strong) ChartNavigation *navigation;
@property (nonatomic, strong) ChartSegmentControl *segment;
@property (nonatomic, strong) ChartDate *subdate;
@property (nonatomic, strong) ChartHUD *chartHUD;
@property (nonatomic, strong) ChartTableView *table;

@property (nonatomic, assign) NSInteger navigationIndex;
@property (nonatomic, assign) NSInteger segmentIndex;

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) BookChartModel *model;
@property (nonatomic, strong) BookDetailModel *minModel;
@property (nonatomic, strong) BookDetailModel *maxModel;

@property (nonatomic, strong) NSDictionary<NSString *, NSInvocation *> *eventStrategy;

@end


#pragma mark - 实现
@implementation ChartController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = YES;
    _navigationIndex = _navIndex;
    [self setDate:[NSDate date]];
    [self navigation];
    [self segment];
    [self subdate];
    [self table];
    [self chartHUD];
    [self setNavigationIndex:_navigationIndex];
    
    [self updateDateRange];
    [self monitorNotification];
    [self getYearBookRequest:self.date.year];
}

// 监听通知
- (void)monitorNotification {
    @weakify(self)
    // 删除记账
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:NOTIFICATION_BOOK_DELETE object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
        @strongify(self)
        [self setDate:[NSDate date]];
        [self getYearBookRequest:self.date.year];
        [self updateDateRange];
    }];
    // 修改记账
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:NOTIFICATION_BOOK_UPDATE object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
        @strongify(self)
        [self setDate:[NSDate date]];
        [self getYearBookRequest:self.date.year];
        [self updateDateRange];
    }];
    // 同步数据成功
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:SYNCED_DATA_COMPLETE object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
        @strongify(self)
        [self setDate:[NSDate date]];
        [self getYearBookRequest:self.date.year];
        [self updateDateRange];
    }];
}

// 更新时间范围
- (void)updateDateRange {
    NSString *preStr;
    if (_cmodel) {
        preStr = [NSString stringWithFormat:@"categoryId == %ld", _cmodel.categoryId];
    }else{
        if (_navigationIndex == 1) {
            preStr = [NSString stringWithFormat:@"categoryId >= %d", 33];
        }else{
            preStr = [NSString stringWithFormat:@"categoryId <= %d", 32];
        }
    }
    
    NSMutableArray<BookDetailModel *> *bookArr = [NSUserDefaults getYearModelList:_date.year];
    NSMutableArray<BookDetailModel *> *models = [NSMutableArray kk_filteredArrayUsingPredicate:preStr array:bookArr];
    // 最小时间
    _minModel = ({
        NSDate *minDate = [models valueForKeyPath:@"@min.date"];
        if (minDate) {
            preStr = [NSString stringWithFormat:@"year == %ld AND month == %02ld AND day == %02ld", minDate.year, minDate.month, minDate.day];
        }
        NSMutableArray *arr = [NSMutableArray kk_filteredArrayUsingPredicate:preStr array:models];
        BookDetailModel *model;
        if (arr.count != 0) {
            model = arr[0];
        }
        model;
    });
    
    // 最大时间
    _maxModel = ({
        NSDate *maxDate = [models valueForKeyPath:@"@max.date"];
        if (maxDate) {
            preStr = [NSString stringWithFormat:@"year == %ld AND month == %02ld AND day == %02ld", maxDate.year, maxDate.month, maxDate.day];
        }
        NSMutableArray *arr = [NSMutableArray kk_filteredArrayUsingPredicate:preStr array:models];
        BookDetailModel *model;
        if (arr.count != 0) {
            model = arr[0];
        }
        model;
    });
    
    _subdate.minModel = _minModel;
    _subdate.maxModel = _maxModel;
}

#pragma mark - request
- (void) getYearBookRequest:(NSInteger)year {
    // 先从本地缓存中取
    NSMutableArray<BookDetailModel *> *list = [NSUserDefaults getYearModelList:_date.year];
    if (list && list.count > 0) {
        NSLog(@"这是从缓存中读取的数据");
        BookChartModel *chartModel=[BookChartModel statisticalChart:self.segmentIndex isIncome:self.navigationIndex cmodel:self.cmodel date:self.date arrm:list];
        [self setModel:chartModel];
        return;
    }
    
    // 从网络取
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    [param setValue:@(year) forKey:@"year"];
    
    [self showProgressHUD:@"同步中..."];
    @weakify(self)
    [AFNManager POST:yearBookListRequest params:param complete:^(APPResult *result) {
        @strongify(self)
        [self hideHUD];
        if (result.status == HttpStatusSuccess && result.code == BIZ_SUCCESS) {
            NSMutableArray<BookDetailModel *> *bookArray = [BookDetailModel mj_objectArrayWithKeyValuesArray:result.data];
            [NSUserDefaults saveYearModelList:year array:bookArray];
            BookChartModel *chartModel=[BookChartModel statisticalChart:self.segmentIndex isIncome:self.navigationIndex cmodel:self.cmodel date:self.date arrm:bookArray];
            [self setModel:chartModel];
        } else {
            // 当请求失败时，清空当前显示的列表数据
            // TODO 增加点击重试按钮
            //[self setModels:nil];
            [self showTextHUD:result.msg delay:1.f];
        }
    }];
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
    _table.model = model;
}

- (void)setNavigationIndex:(NSInteger)navigationIndex {
    _navigationIndex = navigationIndex;
    _navigation.navigationIndex = navigationIndex;
    _subdate.navigationIndex = navigationIndex;
    _table.navigationIndex = navigationIndex;
}

- (void)setSegmentIndex:(NSInteger)segmentIndex {
    _segmentIndex = segmentIndex;
    _subdate.segmentIndex = segmentIndex;
    _table.segmentIndex = segmentIndex;
}


#pragma mark - get
- (ChartNavigation *)navigation {
    if (!_navigation) {
        @weakify(self)
        _navigation = [ChartNavigation loadFirstNib:CGRectMake(0, 0, SCREEN_WIDTH, NavigationBarHeight)];
        [_navigation setCmodel:_cmodel];
        [[_navigation.button rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(UIControl *button) {
            @strongify(self)
            [self.chartHUD show];
        }];
        [self.view addSubview:_navigation];
    }
    return _navigation;
}

- (ChartSegmentControl *)segment {
    if (!_segment) {
        @weakify(self)
        _segment = [ChartSegmentControl loadFirstNib:CGRectMake(0, NavigationBarHeight, SCREEN_WIDTH, countcoordinatesX(50))];
        [[_segment.seg rac_signalForControlEvents:UIControlEventValueChanged] subscribeNext:^(UISegmentedControl *seg) {
            @strongify(self)
            [self setDate:({
                NSInteger index = seg.selectedSegmentIndex;
                NSIndexPath *indexPath = self.subdate.selectIndexs[index];
                ChartSubModel *model = self.subdate.sModels[index][indexPath.row];
                NSInteger month = model.month == -1 ? 1 : model.month;
                NSInteger day = model.day == -1 ? 1 : model.day;
                NSDate *date = [NSDate dateWithYMD:[NSString stringWithFormat:@"%ld-%02ld-%02ld", model.year, month, day]];
                date;
            })];
            [self setSegmentIndex:seg.selectedSegmentIndex];
//            [self setModel:[BookChartModel statisticalChart:self.segmentIndex isIncome:self.navigationIndex cmodel:self.cmodel date:self.date]];
            [self getYearBookRequest:self.date.year];
        }];
        [self.view addSubview:_segment];
    }
    return _segment;
}

- (ChartDate *)subdate {
    if (!_subdate) {
        @weakify(self)
        _subdate = [ChartDate loadCode:CGRectMake(0, _segment.bottom, SCREEN_WIDTH, countcoordinatesX(45))];
        [_subdate setComplete:^(ChartSubModel *model) {
            @strongify(self)
            NSInteger month = model.month == -1 ? 1 : model.month;
            NSInteger day = model.day == -1 ? 1 : model.day;
            NSString *str = [NSString stringWithFormat:@"%ld-%02ld-%02ld", model.year, month, day];
            [self setDate:[NSDate dateWithYMD:str]];
//            [self setModel:[BookChartModel statisticalChart:self.segmentIndex isIncome:self.navigationIndex cmodel:self.cmodel date:self.date]];
            [self getYearBookRequest:self.date.year];
        }];
        [self.view addSubview:_subdate];
    }
    return _subdate;
}

- (ChartTableView *)table {
    if (!_table) {
        _table = [ChartTableView initWithFrame:({
            CGFloat top = self.subdate.bottom;
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
            [self updateDateRange];
//            [self setModel:[BookChartModel statisticalChart:self.segmentIndex isIncome:self.navigationIndex cmodel:self.cmodel date:self.date]];
            [self getYearBookRequest:self.date.year];
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
