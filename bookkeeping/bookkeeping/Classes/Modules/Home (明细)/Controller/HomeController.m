/**
 * 首页
 * @author 郑业强 2018-12-16 创建文件
 */

#import "HomeController.h"
#import "HomeNavigation.h"
#import "HomeHeader.h"
#import "HomeList.h"
#import "HomeListSubCell.h"
#import "HOME_EVENT.h"
#import "BKModel.h"
#import "BookDetailController.h"
#import "MineController.h"
#import "ChartController.h"
#import "LOGIN_NOTIFICATION.h"
#import "ACAListModel.h"
#import "UIViewController+HBD.h"
#import "UIButton+EnlargeTouchArea.h"

#pragma mark - 声明
@interface HomeController()

@property (nonatomic, strong) HomeNavigation *navigation;
@property (nonatomic, strong) HomeHeader *header;
@property (nonatomic, strong) HomeList *list;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSMutableArray<BKMonthModel *> *models;
@property (nonatomic, strong) NSDictionary<NSString *, NSInvocation *> *eventStrategy;

@end


#pragma mark - 实现
@implementation HomeController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = YES;
    [self navigation];
    [self header];
    [self list];
    [self addButton];
    [self setDate:[NSDate date]];
    [self monitorNotification];
    [self setModels:[BKMonthModel statisticalMonthWithYear:_date.year month:_date.month]];

    // 已经登录
    UserModel *model = [UserInfo loadUserInfo];
    if (model.token && model.token.length != 0) {
        [self.view syncedDataRequest];
    }
}

// 监听通知
- (void)monitorNotification {
    // 记账
    @weakify(self)
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:NOT_BOOK_COMPLETE object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
        @strongify(self)
        [self setModels:[BKMonthModel statisticalMonthWithYear:self.date.year month:self.date.month]];
    }];
    // 删除记账
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:NOT_BOOK_DELETE object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
        @strongify(self)
        [self setModels:[BKMonthModel statisticalMonthWithYear:self.date.year month:self.date.month]];
    }];
    // 登录成功
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:LOPGIN_LOGIN_COMPLETE object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
        @strongify(self)
        [self.view syncedDataRequest];
    }];
    // 退出登录
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:LOPGIN_LOGOUT_COMPLETE object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
        @strongify(self)
        [self setModels:[BKMonthModel statisticalMonthWithYear:self.date.year month:self.date.month]];
    }];
    // 同步数据成功
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:SYNCED_DATA_COMPLETE object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
        @strongify(self)
        [self setModels:[BKMonthModel statisticalMonthWithYear:self.date.year month:self.date.month]];
    }];
}


#pragma mark - set
- (void)setModels:(NSMutableArray<BKMonthModel *> *)models {
    _models = models;
    @weakify(self)
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self)
        self.header.models = models;
        self.list.models = models;
    });
}

- (void)setDate:(NSDate *)date {
    _date = date;
    _header.date = date;
}


#pragma mark - 事件
- (void)routerEventWithName:(NSString *)eventName data:(id)data {
    [self handleEventWithName:eventName data:data];
}

- (void)handleEventWithName:(NSString *)eventName data:(id)data {
    NSInvocation *invocation = self.eventStrategy[eventName];
    [invocation setArgument:&data atIndex:2];
    [invocation invoke];
    [super routerEventWithName:eventName data:data];
}

// 点击月份
- (void)homeMonthClick:(id)data {
    @weakify(self)
    NSDate *date = self.date;
    NSDate *min = [NSDate br_setYear:2000 month:1 day:1];
    NSDate *max = [NSDate br_setYear:[NSDate date].year + 3 month:12 day:31];
    
    // 1.创建日期选择器
    BRDatePickerView *datePickerView = [[BRDatePickerView alloc]init];
    // 2.设置属性
    datePickerView.pickerMode = BRDatePickerModeYM;
    datePickerView.title = @"选择日期";
    datePickerView.selectDate = date;
    datePickerView.minDate = min;
    datePickerView.maxDate = max;
    datePickerView.isAutoSelect = false;
    datePickerView.resultBlock = ^(NSDate *selectDate, NSString *selectValue) {
        NSLog(@"选择的值：%@", selectValue);
        @strongify(self)
        [self setDate:[NSDate dateWithYM:selectValue]];
        [self setModels:[BKMonthModel
                         statisticalMonthWithYear:self.date.year month:self.date.month]];
    };

    // 3.显示
    [datePickerView show];
}

// 下拉
- (void)homeTablePull:(id)data {
    [self setDate:[self.date offsetMonths:1]];
    [self setModels:[BKMonthModel statisticalMonthWithYear:_date.year month:_date.month]];
}

// 上拉
- (void)homeTableUp:(id)data {
    [self setDate:[self.date offsetMonths:-1]];
    [self setModels:[BKMonthModel statisticalMonthWithYear:_date.year month:_date.month]];
}

// 删除Cell
- (void)homeTableCellRemove:(HomeListSubCell *)cell {
    // 删除
    [NSUserDefaults removeBookModel:cell.model];
    // 更新
    [[NSNotificationCenter defaultCenter] postNotificationName:NOT_BOOK_DELETE object:nil];
}

// 点击Cell
- (void)homeTableCellClick:(BKModel *)model {
    @weakify(self)
    BookDetailController *vc = [[BookDetailController alloc] init];
    vc.model = model;
    vc.complete = ^{
        @strongify(self)
        [self setModels:[BKMonthModel statisticalMonthWithYear:self.date.year month:self.date.month]];
    };
    [self.navigationController pushViewController:vc animated:true];
}

#pragma mark - get
- (HomeNavigation *)navigation {
    if (!_navigation) {
        _navigation = [HomeNavigation loadFirstNib:CGRectMake(0, 0, SCREEN_WIDTH, NavigationBarHeight)];
        
        // push 到 MineController
        [[_navigation.mineButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(UIControl *button) {
            MineController *vc = [[MineController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }];
        [self.view addSubview:_navigation];
        
        // 增大可点击区域，上下左右各 10
        [_navigation.statisticsBtn setEnlargeEdgeWithTop:10 right:10 bottom:10 left:10];
        // push 到 ChartController
        [[_navigation.statisticsBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(UIControl *button) {
            ChartController *vc = [[ChartController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }];
        
        [self.view addSubview:_navigation];
    }
    return _navigation;
}

- (HomeHeader *)header {
    if (!_header) {
        _header = [HomeHeader loadFirstNib:CGRectMake(0, _navigation.bottom, SCREEN_WIDTH, countcoordinatesX(64))];
        [self.view addSubview:_header];
    }
    return _header;
}

- (HomeList *)list {
    if (!_list) {
        _list = [HomeList loadCode:({
            CGFloat top = CGRectGetMaxY(_header.frame);
            CGFloat height = SCREEN_HEIGHT - top;
            CGRectMake(0, top, SCREEN_WIDTH, height);
        })];
        [self.view addSubview:_list];
    }
    return _list;
}

- (void) addButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(self.view.frame.size.width/2 - 40, self.view.frame.size.height-120, 80, 80);
    [button setImage:[UIImage imageNamed:@"tabbar_add_n.png"] forState:0];
    [button setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    
    // 设置阴影
    button.layer.shadowColor = [UIColor grayColor].CGColor;
    // 阴影的大小，x 往右和 y 往下是正
    button.layer.shadowOffset = CGSizeMake(5, 5);
    // 阴影的扩散范围，相当于 blur radius，也是 shadow 的渐变距离，从外围开始，往里渐变 shadowRadius 距离
    button.layer.shadowRadius = 5;
    // 阴影的不透明度
    button.layer.shadowOpacity = 0.5;
    
    [self.view addSubview:button];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(pushController)];
    [button addGestureRecognizer:tapGesture];
}

- (void)pushController{
    BKCController *vc = [[BKCController alloc] init];
    BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController:vc];
    // Modal Presentation Styles（弹出风格）
    nav.modalPresentationStyle = UIModalPresentationCurrentContext;
    self.navigationController.definesPresentationContext = NO;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)pushToChartController:(id)data {
    ChartController *vc = [[ChartController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (NSDictionary<NSString *, NSInvocation *> *)eventStrategy {
    if (!_eventStrategy) {
        _eventStrategy = @{
            HOME_MONTH_CLICK: [self createInvocationWithSelector:@selector(homeMonthClick:)],
            HOME_TABLE_PULL: [self createInvocationWithSelector:@selector(homeTablePull:)],
            HOME_TABLE_UP: [self createInvocationWithSelector:@selector(homeTableUp:)],
            HOME_CELL_REMOVE: [self createInvocationWithSelector:@selector(homeTableCellRemove:)],
            HOME_CELL_CLICK: [self createInvocationWithSelector:@selector(homeTableCellClick:)],
            HOME_PAY_CLICK: [self createInvocationWithSelector:@selector(pushToChartController:)],
            HOME_INCOME_CLICK: [self createInvocationWithSelector:@selector(pushToChartController:)],
        };
    }
    return _eventStrategy;
}


@end
