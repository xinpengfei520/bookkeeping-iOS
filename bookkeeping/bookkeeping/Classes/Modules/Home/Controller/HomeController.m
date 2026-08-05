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
@property (nonatomic, assign) BOOL replayingFailedBooks;    // 离线队列重放中(防重入)
@property (nonatomic, assign) BOOL pendingInitialLoad;     // 后台启动时推迟首屏加载

@end


#pragma mark - 实现
@implementation HomeController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.prefersNavigationBarHidden = YES;
    [self navigation];
    [self header];
    [self list];
    [self addButton];
    [self setDate:[NSDate date]];
    [self monitorNotification];

    // Siri 的「记一笔」（AppIntents）会在后台把 App 进程拉起来执行，此时
    // 走 Face ID 验证必然失败、拉网络同步也没意义 —— 推迟到真正进前台再做。
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        self.pendingInitialLoad = YES;
        return;
    }
    [self startInitialLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.pendingInitialLoad) {
        self.pendingInitialLoad = NO;
        [self startInitialLoad];
    }
    // 首页是根控制器，每次回到前台/回到首页都试着把离线队列补发出去
    [self replayPendingBookOps];
}

// 首屏加载：Face ID 开着就先验证，验证通过再取数据
- (void)startInitialLoad {
    // 从缓存中取出 PIN_SETTING_FACE_ID 的值，如果没有则默认为 0
    NSNumber *faceId = [NSUserDefaults objectForKey:PIN_SETTING_FACE_ID];
    if ([faceId boolValue] == true) {
        [self verifyFaceID];
    } else {
        [self getData];
    }
}

- (void)getData{
    if ([UserInfo isLogin]) {
        [self syncDataRequest:_date.year month:_date.month];
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
            KKLog(@"FaceID verify success~");
            [self getData];
        });
    } failure:^(NSError *tyError, LAContextErrorType feedType) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // @TODO
            if (tyError.code == -8) {
                // 超出TouchID尝试次数或FaceID尝试次数，已被锁
                KKLog(@"超出TouchID尝试次数或FaceID尝试次数，已被锁========");
            }
            else if (tyError.code == -7) {
                // 未开启TouchID权限(没有可用的指纹)
                KKLog(@"未开启TouchID权限(没有可用的指纹)========");
            }
            else if (tyError.code == -6) {
                if (IS_IPHONE_X) {
                    // iPhoneX 设置里面没有开启FaceID权限
                    KKLog(@"iPhoneX 设置里面没有开启FaceID权限========");
                }
                else {
                    // 非iPhoneX手机且该手机不支持TouchID(如iPhone5、iPhone4s)
                    KKLog(@"非iPhoneX手机且该手机不支持TouchID(如iPhone5、iPhone4s)========");
                }
            }
            else {
                // 其他error情况 如用户主动取消等
                KKLog(@"其他error情况 如用户主动取消等========");
            }
        });
    }];
}

// 监听通知
- (void)monitorNotification {
    // 记账
    @weakify(self)
    [self kk_observeNotification:NOTIFICATION_BOOK_ADD usingBlock:^(NSNotification *x) {
        @strongify(self)
        BookDetailModel *model = x.object;
        [self addBookRequest:model];
    }];
    // 删除记账
    [self kk_observeNotification:NOTIFICATION_BOOK_DELETE usingBlock:^(NSNotification *x) {
        @strongify(self)
        BookDetailModel *model = x.object;
        [self deleteBookRequest:model];
    }];
    // 修改记账
    [self kk_observeNotification:NOTIFICATION_BOOK_UPDATE_HOME usingBlock:^(NSNotification *x) {
        @strongify(self)
        BookDetailModel *model = x.object;
        [self updateBookRequest:model];
    }];
    // 登录成功
    [self kk_observeNotification:USER_LOGIN_COMPLETE usingBlock:^(id x) {
        @strongify(self)
        [self syncDataRequest:self.date.year month:self.date.month];
    }];
    // 退出登录
    [self kk_observeNotification:USER_LOGOUT_COMPLETE usingBlock:^(id x) {
        @strongify(self)
        [self setModels:[BookMonthModel statisticalMonthWithYear:self.date.year month:self.date.month]];
    }];
    // token 过期
    [self kk_observeNotification:MINE_TOKEN_EXPIRED usingBlock:^(id x) {
        @strongify(self)
        // 重放请求碰上 token 过期时 complete 不会回调，这里把防重入标记复位，
        // 否则重新登录后离线队列永远不再尝试。
        self.replayingFailedBooks = NO;
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
                KKLog(@"刷新 token 成功");
            } else {
                KKLog(@"刷新 token 失败");
            }
        }];
    }
}

// 多币种三字段：要么全给、要么全不给。人民币记账就是"全不给"，
// 请求体与改造前逐字节相同。currency 必须大写、汇率 6 位小数，
// 否则服务端的跨字段一致性校验会直接拒绝保存。
- (void)appendCurrencyParams:(NSMutableDictionary *)param model:(BookDetailModel *)model {
    if (![model isForeignCurrency]) {
        return;
    }
    [param setValue:[model.currency uppercaseString] forKey:@"currency"];
    [param setValue:@([[KKCurrency formatAmount:model.originalPrice] doubleValue]) forKey:@"originalPrice"];
    [param setValue:@([[KKCurrency formatRate:model.exchangeRate] doubleValue]) forKey:@"exchangeRate"];
}

// 新增记账的请求体（addBookRequest 与离线队列重放共用同一份构建逻辑）
- (NSMutableDictionary *)saveParamsWithModel:(BookDetailModel *)model {
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    [param setValue:@(model.year) forKey:@"year"];
    [param setValue:@(model.month) forKey:@"month"];
    [param setValue:@(model.day) forKey:@"day"];
    [param setValue:@(model.price) forKey:@"price"];
    [param setValue:model.mark forKey:@"mark"];
    [param setValue:@(model.categoryId) forKey:@"categoryId"];
    [self appendCurrencyParams:param model:model];
    return param;
}

- (void)addBookRequest:(BookDetailModel *)model {
    // 判断添加的记账年月是否是当前页面显示的记账年月
    if (model.year == self.date.year && model.month == self.date.month) {
        [self setModels:[BookMonthModel addData:self.models model:model]];
    }

    NSInteger oldBookId = model.bookId;
    NSMutableDictionary *param = [self saveParamsWithModel:model];

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
            
            // 如果没有在当前月份时，说明记的是其他月份的账，则加载记账年月的数据
            if (model.month != self.date.month) {
                NSString *yearMonth = [NSString stringWithFormat:@"%ld-%ld", (long)model.year,(long)model.month];
                KKLog(@"当前记账的年月：%@", yearMonth);
                [self setDate:[NSDate dateWithYM:yearMonth]];
                [self setModels:[BookMonthModel statisticalMonthWithYear:model.year month:model.month]];
            }

            // 这次保存走通了说明网络没问题，顺手把之前离线欠下的账补发出去
            [self replayPendingBookOps];
        }
        // 传输层失败（没网/超时）：先落到本地 + 入离线队列，等网络恢复自动补发。
        // 之前这里只弹个 toast，UI 上看着记上了、重启就没了 —— 那才是最坑的。
        else if (result.status != HttpStatusSuccess) {
            [NSUserDefaults insertBookModel:model];
            [NSUserDefaults enqueuePendingAdd:model];
            [self showTextHUD:KKLocalized(@"网络不给力，已保存在本机，联网后自动同步") delay:1.5f];
        }
        // 业务拒绝（参数校验不过等）：服务端永远不会收这条，把乐观插入回滚掉，
        // 不能让用户以为记上了。
        else {
            if (model.year == self.date.year && model.month == self.date.month) {
                [self setModels:[BookMonthModel removeData:self.models model:model]];
            }
            [self showTextHUD:result.msg delay:1.f];
        }
    }];
}

#pragma mark - 离线待办队列重放
// 把 PIN_BOOK_FAILED 里积压的增/改/删逐条补发到服务端。串行发送：
// 一旦再次碰到传输失败就整轮停下（说明还没网），等下一次触发。
// 触发点：viewDidAppear、每次在线请求成功之后。
- (void)replayPendingBookOps {
    if (self.replayingFailedBooks || ![UserInfo isLogin]) {
        return;
    }
    NSMutableArray<KKPendingBookOp *> *queue = [NSUserDefaults getPendingBookOps];
    if (queue.count == 0) {
        return;
    }
    self.replayingFailedBooks = YES;
    [self replayPendingOps:queue index:0];
}

- (void)replayPendingOps:(NSMutableArray<KKPendingBookOp *> *)queue index:(NSInteger)index {
    if (index >= (NSInteger)queue.count) {
        self.replayingFailedBooks = NO;
        return;
    }
    KKPendingBookOp *op = queue[index];
    BookDetailModel *model = op.model;

    NSString *url = nil;
    NSMutableDictionary *param = nil;
    switch (op.type) {
        case KKBookOpTypeAdd:
            url = bookDetailSaveRequest;
            param = [self saveParamsWithModel:model];
            break;
        case KKBookOpTypeUpdate:
            url = bookDetailUpdateRequest;
            param = [self saveParamsWithModel:model];
            [param setValue:@(model.bookId) forKey:@"bookId"];
            break;
        case KKBookOpTypeDelete:
            url = bookDetailDeleteRequest;
            param = [NSMutableDictionary dictionaryWithObject:@(model.bookId) forKey:@"bookId"];
            break;
    }

    @weakify(self)
    [AFNManager POST:url params:param complete:^(APPResult *result) {
        @strongify(self)
        if (!self) {
            return;
        }
        // 还是没网：这轮到此为止，队列原样保留
        if (result.status != HttpStatusSuccess) {
            self.replayingFailedBooks = NO;
            return;
        }

        // 无论成功还是业务拒绝都要出队 —— 业务拒绝重试多少次服务端都不会收
        // （类别已删 / 校验不过 / 记录不存在），不能让它无限重试。
        [NSUserDefaults dequeuePendingBookOpForBookId:model.bookId];

        if (result.code == BIZ_SUCCESS) {
            if (op.type == KKBookOpTypeAdd) {
                NSInteger oldBookId = model.bookId;     // 离线时分配的临时 id
                [NSUserDefaults removeBookModel:model];
                NSDictionary *dic = [result.data isKindOfClass:[NSDictionary class]] ? result.data : nil;
                model.bookId = [[dic objectForKey:@"bookId"] integerValue];
                [NSUserDefaults insertBookModel:model];

                // 补发的这条正好在当前展示的月份，把临时 id 的那条换成服务端 id
                if (model.year == self.date.year && model.month == self.date.month) {
                    [self setModels:[BookMonthModel replaceData:self.models model:model bookId:oldBookId]];
                }
            }
            // update / delete 的本地状态在入队时就已经是目标状态了，补发成功无需再动
        } else {
            // 新增被拒 → 本地这条服务端永远不会有，删掉并告知；
            // 改/删被拒 → 本地保留当前状态，下次全量同步以服务端为准纠正。
            if (op.type == KKBookOpTypeAdd) {
                [NSUserDefaults removeBookModel:model];
                if (model.year == self.date.year && model.month == self.date.month) {
                    [self setModels:[BookMonthModel removeData:self.models model:model]];
                }
            }
            NSString *reason = result.msg.length ? result.msg : @"";
            [self showTextHUD:[NSString stringWithFormat:KKLocalized(@"有一笔离线记账未能同步：%@"), reason] delay:2.f];
        }
        [self replayPendingOps:queue index:index + 1];
    }];
}

- (void)deleteBookRequest:(BookDetailModel *)model {
    // 判断添加的记账年月是否是当前页面显示的记账年月
    if (model.year == self.date.year && model.month == self.date.month) {
        [self setModels:[BookMonthModel removeData:self.models model:model]];
    }

    // 本地立刻删（乐观）：旧实现只在成功分支删本地，失败时界面已经移除、
    // SQLite 还留着，切个月份回来这条记录就"复活"了。
    [NSUserDefaults removeBookModel:model];

    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    [param setValue:@(model.bookId) forKey:@"bookId"];

    [AFNManager POST:bookDetailDeleteRequest params:param complete:^(APPResult *result) {
        if (result.status == HttpStatusSuccess && result.code == BIZ_SUCCESS) {
            [self replayPendingBookOps];
        }
        // 没网：入队等联网补发（本地已删，界面与存储一致）
        else if (result.status != HttpStatusSuccess) {
            [NSUserDefaults enqueuePendingDelete:model];
            [self showTextHUD:KKLocalized(@"网络不给力，已在本机删除，联网后自动同步") delay:1.5f];
        }
        // 业务拒绝：服务端明确不接受这次删除，本地回滚
        else {
            [NSUserDefaults insertBookModel:model];
            if (model.year == self.date.year && model.month == self.date.month) {
                [self setModels:[BookMonthModel statisticalMonthWithYear:model.year month:model.month]];
            }
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
    [self appendCurrencyParams:param model:model];

    // 本地立刻改（乐观）：BookController 是就地修改同一个 model 对象并已发出
    // 通知，界面早就是新值了；旧实现只在成功分支写 SQLite，失败时重启就回滚。
    [NSUserDefaults replaceBookModel:model];
    // 有可能改了年月，跳到修改后那个月
    NSString *yearMonth = [NSString stringWithFormat:@"%ld-%ld", (long)model.year, (long)model.month];
    [self setDate:[NSDate dateWithYM:yearMonth]];
    [self setModels:[BookMonthModel statisticalMonthWithYear:model.year month:model.month]];

    [AFNManager POST:bookDetailUpdateRequest params:param complete:^(APPResult *result) {
        if (result.status == HttpStatusSuccess && result.code == BIZ_SUCCESS) {
            [self replayPendingBookOps];
        }
        // 没网：入队等联网补发（本地已是新值，界面与存储一致）
        else if (result.status != HttpStatusSuccess) {
            [NSUserDefaults enqueuePendingUpdate:model];
            [self showTextHUD:KKLocalized(@"网络不给力，已改在本机，联网后自动同步") delay:1.5f];
        }
        // 业务拒绝：服务端不接受这次修改，本地保留改动但明确告知未同步，
        // 下次全量同步会以服务端为准纠正回来
        else {
            [self showTextHUD:result.msg delay:1.5f];
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
    [self showProgressHUD:KKLocalized(@"同步数据...")];
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
    datePickerView.pickerStyle = [self kk_localizedPickerStyle];
    datePickerView.pickerMode = BRDatePickerModeYM;
    datePickerView.title = KKLocalized(@"选择日期");
    datePickerView.selectDate = date;
    datePickerView.minDate = min;
    datePickerView.maxDate = max;
    datePickerView.isAutoSelect = false;
    datePickerView.resultBlock = ^(NSDate *selectDate, NSString *selectValue) {
        KKLog(@"选择的值：%@", selectValue);
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
        _navigation = [HomeNavigation loadCode:CGRectMake(0, 0, SCREEN_WIDTH, NavigationBarHeight)];
        
        // 头像/菜单按钮先隐藏 —— me 已是独立 tab，顶部入口冗余。如果将来想留个
        // 直达 tab 的快捷点，把 hidden = NO 取消即可，tap 行为已挪到下面那个
        // closure；但目前用户希望整体藏起来。
        _navigation.mineButton.hidden = YES;
        [self.view addSubview:_navigation];
        
        // 增大可点击区域，上下左右各 10
        [_navigation.statisticsBtn setEnlargeEdgeWithTop:10 right:10 bottom:10 left:10];
        // push 到 SearchViewController
        [_navigation.statisticsBtn kk_addEventHandler:^(UIControl *button) {
            SearchViewController *vc = [[SearchViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        } forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:_navigation];
    }
    return _navigation;
}

- (HomeHeader *)header {
    if (!_header) {
        _header = [[HomeHeader alloc] initWithFrame:CGRectMake(0, _navigation.bottom, SCREEN_WIDTH, countcoordinatesX(64))];
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

// BRPickerView 自带 bundle 的"取消/确定"按钮文案不响应 KKI18n 偏好（用 in-app
// override 而非 AppleLanguages，BRPickerView 看不到我们的语言）。每个调用点
// 显式覆盖 cancel/done btn title。这个 helper 给本文件 4-5 个 picker 调用点
// 共用。Bill / Timing / BKCKeyboard 那 3 处也各自 inline 同样的 style 设置。
- (BRPickerStyle *)kk_localizedPickerStyle {
    BRPickerStyle *style = [[BRPickerStyle alloc] init];
    style.cancelBtnTitle = KKLocalized(@"取消");
    style.doneBtnTitle = KKLocalized(@"确定");
    return style;
}

- (void)addButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    // 老布局 y = height-120 时，按钮 frame 底边 = height-40，落在 tab bar
    // 范围内（TabbarHeight≈83pt），点击下半区会被 tab bar 截走，把人带到
    // "我的" tab。改为 height-200 让按钮整体挂在 tab bar 上方，并用
    // setEnlargeEdgeWithTop:... 在视觉 80×80 之外再加 10pt 安全 hit-zone。
    button.frame = CGRectMake(self.view.frame.size.width/2 - 40, self.view.frame.size.height-200, 80, 80);
    [button setImage:[UIImage imageNamed:@"tabbar_add_n.png"] forState:0];
    [button setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    [button setEnlargeEdgeWithTop:10 right:10 bottom:10 left:10];
    
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
