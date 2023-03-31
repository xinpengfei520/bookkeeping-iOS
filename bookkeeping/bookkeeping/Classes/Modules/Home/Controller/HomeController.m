/**
 * 首页
 * @author 郑业强 2018-12-16 创建文件
 */

#import "HomeController.h"
#import "HomeNavigation.h"
#import "HomeHeader.h"
#import "HomeList.h"
#import "HomeListSubCell.h"
#import "BookDetailModel.h"
#import "BookMonthModel.h"
#import "ACAListModel.h"
#import "UIButton+EnlargeTouchArea.h"
#import "LAContextManager.h"

#pragma mark - 声明
@interface HomeController()

@property (nonatomic, strong) HomeNavigation *navigation;
@property (nonatomic, strong) HomeHeader *header;
@property (nonatomic, strong) HomeList *list;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSMutableArray<BookMonthModel *> *models;
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
    
    // 从缓存中取出 PIN_SETTING_FACE_ID 的值，如果没有则默认为 0
    NSNumber *faceId = [NSUserDefaults objectForKey:PIN_SETTING_FACE_ID];
    if ([faceId boolValue] == true) {
        [self verifyFaceID];
    }else{
        [self getData];
    }
}

- (void)getData{
    if ([UserInfo isLogin]) {
        [self syncDataRequest:_date.year month:_date.month];
        //[self.view syncedDataRequest];
        [self refreshToken];
    }else{
        // 设置空数据
        NSMutableArray<BookMonthModel *> *list = [NSMutableArray array];
        [self setModels:list];
    }
}

- (void)verifyFaceID {
    @weakify(self)
    [LAContextManager callLAContextManagerWithController:self success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self)
            NSLog(@"FaceID verify success~");
            [self getData];
        });
    } failure:^(NSError *tyError, LAContextErrorType feedType) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // @TODO
            if (tyError.code == -8) {
                // 超出TouchID尝试次数或FaceID尝试次数，已被锁
                NSLog(@"超出TouchID尝试次数或FaceID尝试次数，已被锁========");
            }
            else if (tyError.code == -7) {
                // 未开启TouchID权限(没有可用的指纹)
                NSLog(@"未开启TouchID权限(没有可用的指纹)========");
            }
            else if (tyError.code == -6) {
                if (IS_IPHONE_X) {
                    // iPhoneX 设置里面没有开启FaceID权限
                    NSLog(@"iPhoneX 设置里面没有开启FaceID权限========");
                }
                else {
                    // 非iPhoneX手机且该手机不支持TouchID(如iPhone5、iPhone4s)
                    NSLog(@"非iPhoneX手机且该手机不支持TouchID(如iPhone5、iPhone4s)========");
                }
            }
            else {
                // 其他error情况 如用户主动取消等
                NSLog(@"其他error情况 如用户主动取消等========");
            }
        });
    }];
}

// 监听通知
- (void)monitorNotification {
    // 记账
    @weakify(self)
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:NOTIFICATION_BOOK_ADD object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(NSNotification *x) {
        @strongify(self)
        BookDetailModel *model = x.object;
        [self addBookRequest:model];
    }];
    // 删除记账
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:NOTIFICATION_BOOK_DELETE object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(NSNotification *x) {
        @strongify(self)
        BookDetailModel *model = x.object;
        [self deleteBookRequest:model];
    }];
    // 修改记账
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:NOTIFICATION_BOOK_UPDATE_HOME object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(NSNotification *x) {
        @strongify(self)
        BookDetailModel *model = x.object;
        [self updateBookRequest:model];
    }];
    // 登录成功
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:USER_LOGIN_COMPLETE object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
        @strongify(self)
        [self syncDataRequest:self.date.year month:self.date.month];
    }];
    // 退出登录
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:USER_LOGOUT_COMPLETE object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
        @strongify(self)
        [self setModels:[BookMonthModel statisticalMonthWithYear:self.date.year month:self.date.month]];
    }];
    // 同步数据成功
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:SYNCED_DATA_COMPLETE object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
        @strongify(self)
        [self setModels:[BookMonthModel statisticalMonthWithYear:self.date.year month:self.date.month]];
    }];
    // token 过期
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:MINE_TOKEN_EXPIRED object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
        @strongify(self)
        [self pushToLoginController];
    }];
}


#pragma mark - set
- (void)setModels:(NSMutableArray<BookMonthModel *> *)models {
    _models = models;
    @weakify(self)
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self)
        self.header.models = models;
        self.list.models = models;
    });
}

#pragma mark - request
- (void)refreshToken {
    if ([UserInfo authorizationWillExpired]) {
        [AFNManager POST:refreshTokenRequest params:nil complete:^(APPResult *result) {
            [self hideHUD];
            if (result.status == HttpStatusSuccess && result.code == BIZ_SUCCESS) {
                NSLog(@"刷新 token 成功");
            } else {
                NSLog(@"刷新 token 失败");
            }
        }];
    }
}

- (void)addBookRequest:(BookDetailModel *)model {
    // 判断添加的记账年月是否是当前页面显示的记账年月
    if (model.year == self.date.year && model.month == self.date.month) {
        [self setModels:[BookMonthModel addData:self.models model:model]];
    }
    
    NSInteger oldBookId = model.bookId;
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    [param setValue:@(model.year) forKey:@"year"];
    [param setValue:@(model.month) forKey:@"month"];
    [param setValue:@(model.day) forKey:@"day"];
    [param setValue:@(model.price) forKey:@"price"];
    [param setValue:model.mark forKey:@"mark"];
    [param setValue:@(model.categoryId) forKey:@"categoryId"];
    
    [AFNManager POST:bookDetailSaveRequest params:param complete:^(APPResult *result) {
        if (result.status == HttpStatusSuccess && result.code == BIZ_SUCCESS) {
            NSDictionary *dic = [[NSDictionary alloc]initWithDictionary:result.data];
            NSNumber *bookId = [dic objectForKey:@"bookId"];
            model.bookId = [bookId intValue];
            
            // 判断添加的记账年月是否是当前页面显示的记账年月
            if (model.year == self.date.year && model.month == self.date.month) {
                [self setModels:[BookMonthModel replaceData:self.models model:model bookId:oldBookId]];
            }
            
            // 添加记账
            [NSUserDefaults insertBookModel:model];
            // 更新备注
            [MarkModel update:model errorMsg:^(NSString *errorMsg) {
                [self showTextHUD:errorMsg delay:1.f];
            }];
        } else {
            [self showTextHUD:result.msg delay:1.f];
        }
    }];
}

- (void)deleteBookRequest:(BookDetailModel *)model {
    // 判断添加的记账年月是否是当前页面显示的记账年月
    if (model.year == self.date.year && model.month == self.date.month) {
        [self setModels:[BookMonthModel removeData:self.models model:model]];
    }
    
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    [param setValue:@(model.bookId) forKey:@"bookId"];
    
    [AFNManager POST:bookDetailDeleteRequest params:param complete:^(APPResult *result) {
        if (result.status == HttpStatusSuccess && result.code == BIZ_SUCCESS) {
            [NSUserDefaults removeBookModel:model];
        } else {
            [self showTextHUD:result.msg delay:1.f];
        }
    }];
}

- (void)updateBookRequest:(BookDetailModel *)model {
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    [param setValue:@(model.bookId) forKey:@"bookId"];
    [param setValue:@(model.year) forKey:@"year"];
    [param setValue:@(model.month) forKey:@"month"];
    [param setValue:@(model.day) forKey:@"day"];
    [param setValue:@(model.price) forKey:@"price"];
    [param setValue:model.mark forKey:@"mark"];
    [param setValue:@(model.categoryId) forKey:@"categoryId"];
    
    [AFNManager POST:bookDetailUpdateRequest params:param complete:^(APPResult *result) {
        if (result.status == HttpStatusSuccess && result.code == BIZ_SUCCESS) {
            // 修改本地所有记账
            [NSUserDefaults replaceBookModel:model];
        } else {
            [self showTextHUD:result.msg delay:1.f];
        }
    }];
}

- (void)syncDataRequest:(NSInteger)year month:(NSInteger)month {
    // 先从本地缓存中取
    NSMutableArray<BookMonthModel *> *list = [BookMonthModel statisticalMonthWithYear:_date.year month:_date.month];
    if (list && list.count > 0) {
        [self setModels:list];
        return;
    }
    
    // 从网络取
    [self showProgressHUD:@"同步数据..."];
    @weakify(self)
    [AFNManager POST:allBookListRequest params:nil complete:^(APPResult *result) {
        @strongify(self)
        [self hideHUD];
        if (result.status == HttpStatusSuccess && result.code == BIZ_SUCCESS) {
            NSMutableArray<BookDetailModel *> *bookArray = [BookDetailModel mj_objectArrayWithKeyValuesArray:result.data];
            [NSUserDefaults saveAllBookList:bookArray];
            [self setModels:[BookMonthModel statisticalMonthWithYear:self.date.year month:self.date.month]];
        } else {
            // 当请求失败时，清空当前显示的列表数据
            // TODO 增加点击重试按钮
            [self setModels:nil];
            [self showTextHUD:result.msg delay:1.f];
        }
    }];
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
        [self setModels:[BookMonthModel statisticalMonthWithYear:self.date.year month:self.date.month]];
    };

    // 3.显示
    [datePickerView show];
}

// 下拉
- (void)homeTablePull:(id)data {
    [self setDate:[self.date offsetMonths:1]];
    [self setModels:[BookMonthModel statisticalMonthWithYear:_date.year month:_date.month]];
}

// 上拉
- (void)homeTableUp:(id)data {
    [self setDate:[self.date offsetMonths:-1]];
    [self setModels:[BookMonthModel statisticalMonthWithYear:_date.year month:_date.month]];
}

// 删除Cell
- (void)homeTableCellRemove:(HomeListSubCell *)cell {
    [self deleteBookRequest:cell.model];
}

// 点击Cell
- (void)homeTableCellClick:(NSIndexPath *)indexPath {
    @weakify(self)
    BookDetailModel *model = self.models[indexPath.section].array[indexPath.row];
    BookDetailController *vc = [[BookDetailController alloc] init];
    vc.model = model;
    vc.complete = ^{
    };
    vc.refresh = ^{
        @strongify(self)
        [self.models[indexPath.section] refresh];
        [self.list refresh:indexPath];
        [self.header refresh];
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
        // push 到 SearchViewController
        [[_navigation.statisticsBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(UIControl *button) {
            SearchViewController *vc = [[SearchViewController alloc] init];
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

- (void)addButton {
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
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(pushToBookController)];
    [button addGestureRecognizer:tapGesture];
}

- (void)pushToBookController{
    if ([UserInfo isLogin]) {
        BookController *bookController = [[BookController alloc] init];
        BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController:bookController];
        // Modal Presentation Styles（弹出风格）
        nav.modalPresentationStyle = UIModalPresentationCurrentContext;
        self.navigationController.definesPresentationContext = NO;
        [self presentViewController:nav animated:YES completion:nil];
    }else{
        [self pushToLoginController];
    }
}

/**
 * push 到 ChartController
 * @param index 导航栏下标：0 支出 1 收入
 */
- (void)pushToChartController:(NSString*)index {
    if ([UserInfo isLogin]) {
        ChartController *vc = [[ChartController alloc] init];
        vc.navIndex = [index integerValue];
        vc.isBookDetail = false;
        [self.navigationController pushViewController:vc animated:YES];
    }else{
        [self pushToLoginController];
    }
}

- (void)pushToLoginController {
    @weakify(self)
    LoginController *vc = [[LoginController alloc] init];
    [vc setComplete:^{
        @strongify(self)
        [self syncDataRequest:self.date.year month:self.date.month];
    }];
    BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController:vc];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
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
