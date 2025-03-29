/**
 * 我的 - 定时提醒
 * @author 郑业强 2018-12-18 创建文件
 */

#import "TimeRemindController.h"
#import "TITableView.h"
#import "BottomButton.h"
#import "TIModel.h"
#import "TITableCell.h"
#import "HomeListEmpty.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface TimeRemindController()<UNUserNotificationCenterDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) TITableView *table;
@property (nonatomic, strong) BottomButton *bottom;
@property (nonatomic, strong) NSMutableArray *models;
@property (nonatomic, strong) NSDictionary<NSString *, NSInvocation *> *eventStrategy;
@property (nonatomic, strong) HomeListEmpty *emptyView;

@end

#pragma mark - 实现
@implementation TimeRemindController


#pragma mark - UNUserNotificationCenterDelegate
// iOS 10收到通知
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    // 根据系统版本使用不同的选项
    if (@available(iOS 14.0, *)) {
        // iOS 14 及以上使用新的选项
        completionHandler(UNNotificationPresentationOptionBanner | 
                        UNNotificationPresentationOptionList | 
                        UNNotificationPresentationOptionSound);
    } else {
        // iOS 14 以下使用旧的选项
        completionHandler(UNNotificationPresentationOptionAlert | 
                        UNNotificationPresentationOptionSound);
    }
}

/**
 * 添加通知
 * @param time 时间戳
 */
- (void)addNotification:(NSString *)time {
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = [NSString localizedUserNotificationStringForKey:@"温馨提示" arguments:nil];
        content.sound = [UNNotificationSound defaultSound];
        content.body  = [NSString localizedUserNotificationStringForKey:@"记账时间到了，赶紧记一笔吧！" arguments:nil];
        
        // 周一早上 8：00 上班
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.hour = [[time componentsSeparatedByString:@":"][0] integerValue];
        components.minute = [[time componentsSeparatedByString:@":"][1] integerValue];
        UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:components repeats:YES];
        
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:time content:content trigger:trigger];
        [center addNotificationRequest:request withCompletionHandler:^(NSError *_Nullable error) {
            NSLog(@"成功添加本地推送通知提醒");
        }];
        
        [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
            NSLog(@"getPendingNotification: %@", requests);
        }];
    }
}

/**
 * 移除通知
 * @param time 时间戳
 */
- (void)removeNotification:(NSString *)time {
    if (!time || time.length == 0) {
        NSLog(@"警告：尝试删除空的通知标识符");
        return;
    }
    
    // 获取所有本地通知数组
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    
    NSLog(@"尝试删除通知：%@", time);
    
    // 尝试直接删除
    [center removePendingNotificationRequestsWithIdentifiers:@[time]];
    
    // 备选方案：获取所有通知，手动匹配并删除
    [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
        // 检查是否存在匹配的通知
        NSMutableArray *identifiersToRemove = [NSMutableArray array];
        
        for (UNNotificationRequest *request in requests) {
            // 检查是否是我们要删除的时间通知
            if ([request.identifier isEqualToString:time] || 
                [request.identifier containsString:time]) {
                [identifiersToRemove addObject:request.identifier];
                NSLog(@"找到匹配通知，准备删除: %@", request.identifier);
            }
        }
        
        // 如果找到匹配的通知，删除它们
        if (identifiersToRemove.count > 0) {
            [center removePendingNotificationRequestsWithIdentifiers:identifiersToRemove];
            NSLog(@"删除通知标识符: %@", identifiersToRemove);
        }
        
        // 再次检查是否删除成功
        [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull remainingRequests) {
            BOOL stillExists = NO;
            for (UNNotificationRequest *request in remainingRequests) {
                if ([request.identifier isEqualToString:time]) {
                    stillExists = YES;
                    break;
                }
            }
            
            if (stillExists) {
                NSLog(@"警告：通知删除失败：%@", time);
            } else {
                NSLog(@"通知删除成功：%@", time);
            }
            
            NSLog(@"最终活跃通知列表：%@", remainingRequests);
        }];
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"viewDidLoad - 开始");
    self.hbd_barHidden = NO;
    self.hbd_barTintColor = kColor_Main_Color;
    [self setNavTitle:@"定时提醒"];
    
    // 请求通知权限
    [self requestNotificationPermission];
    
    // 先创建和添加 table
    [self.view addSubview:self.table];
    
    // 再创建和添加 bottom
    [self.view addSubview:self.bottom];
    [self.view bringSubviewToFront:self.bottom];
    
    // 获取存储的数据
    NSMutableArray *savedData = [NSUserDefaults objectForKey:PIN_TIMING];
    NSLog(@"viewDidLoad - 从 NSUserDefaults 获取的数据: %@", savedData);
    
    // 设置数据
    [self setModels:savedData];
    
    // 最后设置空视图
    [self setupUI];
    
    NSLog(@"viewDidLoad - 结束");
    NSLog(@"table frame: %@", NSStringFromCGRect(self.table.frame));
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 获取最新的数据
    NSMutableArray *savedData = [NSUserDefaults objectForKey:PIN_TIMING];
    NSLog(@"viewWillAppear - 从 NSUserDefaults 获取的数据: %@", savedData);
    
    // 设置数据并更新UI
    [self setModels:savedData];
    
    // 检查并显示空状态视图
    BOOL isEmpty = (self.models == nil || self.models.count == 0);
    [self.emptyView setHidden:!isEmpty];
    
    if (isEmpty) {
        // 设置空状态文字
        [self.emptyView updateEmptyText:@"你还没有任何提醒哦～"];
    }
    
    NSLog(@"viewWillAppear - 空状态视图隐藏状态: %@", self.emptyView.isHidden ? @"是" : @"否");
}

// 请求通知权限
- (void)requestNotificationPermission {
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge)
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (granted) {
                NSLog(@"通知权限获取成功");
            } else {
                NSLog(@"通知权限获取失败: %@", error.localizedDescription);
            }
        }];
    }
}

- (void)setupUI {
    // 创建空状态视图
    _emptyView = [[HomeListEmpty alloc] init];
    [_emptyView setHidden:YES];  // 默认隐藏
    [self.view addSubview:_emptyView];
    
    // 设置空状态视图约束
    [_emptyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.bottom.equalTo(self.bottom.mas_top).offset(-1); // 确保与底部按钮的顶部对齐
    }];
}

// 更新列表数据时调用此方法
- (void)updateEmptyViewWithData:(NSArray *)data {
    // 根据数据源判断是否显示空状态
    BOOL isEmpty = (data == nil || data.count == 0);
    NSLog(@"updateEmptyViewWithData - 数据为空: %@, 视图将%@", isEmpty ? @"是" : @"否", isEmpty ? @"显示" : @"隐藏");
    
    [_emptyView setHidden:!isEmpty];
    
    if (isEmpty) {
        // 设置空状态文字
        [_emptyView updateEmptyText:@"你还没有任何提醒哦～"];
    }
}

#pragma mark - 请求

// 添加定时
- (void)addTimingRequest:(NSString *)time {
    NSMutableArray *arrm = [NSUserDefaults objectForKey:PIN_TIMING];
    // 判断设置的时间是否已存在
    if ([arrm containsObject:time]) {
        [self showTextHUD:@"已经添加过该时间的提醒" delay:2.f];
        return;
    }

    // 添加到数组
    [arrm addObject:time];
    // 排序
    [arrm sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    // 缓存起来
    [NSUserDefaults setObject:arrm forKey:PIN_TIMING];
    
    [self setModels:arrm];
    [self.table reloadData];
    [self addNotification:time];
}

// 删除定时
- (void)deleteTimingRequest:(NSString *)time {
    NSMutableArray *arrm = [NSUserDefaults objectForKey:PIN_TIMING];
    
    [arrm removeObject:time];
    [NSUserDefaults setObject:arrm forKey:PIN_TIMING];
        
    [self setModels:arrm];
    [self.table reloadData];
    [self removeNotification:time];
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

// 添加定时
- (void)bottomClick:(id)data {
    @weakify(self)
    // 1.创建日期选择器
    BRDatePickerView *datePickerView = [[BRDatePickerView alloc]init];
    // 2.设置属性
    datePickerView.pickerMode = BRDatePickerModeHM;
    datePickerView.title = @"每天";
    datePickerView.resultBlock = ^(NSDate *selectDate, NSString *selectValue) {
        NSLog(@"选择提醒的时间为每天的：%@", selectValue);
        @strongify(self)
        [self addTimingRequest:selectValue];
    };

    // 3.显示
    [datePickerView show];
}

// 删除cell - 修改参数类型，统一处理
- (void)timeCellDelete:(NSIndexPath *)indexPath {
    // 获取要删除的时间
    NSString *timeToDelete = self.models[indexPath.row];
    
    // 从数据源中移除
    [self.models removeObjectAtIndex:indexPath.row];
    
    // 更新 UserDefaults
    [NSUserDefaults setObject:self.models forKey:PIN_TIMING];
    
    // 刷新表格
    [self.table reloadData];
    
    // 检查是否需要显示空状态
    [self.emptyView setHidden:self.models.count > 0];
    
    // 移除系统通知
    [self removeNotification:timeToDelete];
    
    NSLog(@"提醒已删除：%@", timeToDelete);
}

// 修改为仅处理转发，不重复处理删除逻辑
- (void)routerWithEventName:(NSString *)eventName data:(id)data {
    if ([eventName isEqualToString:TIMING_CELL_DELETE]) {
        // 转发到统一的删除处理方法
        [self timeCellDelete:data];
    }
}

#pragma mark - set
- (void)setModels:(NSArray *)models {
    NSLog(@"setModels - 原始数据: %@", models);
    if (!models) {
        _models = [NSMutableArray array];
    } else {
        _models = [NSMutableArray arrayWithArray:[models mj_JSONObject]];
    }
    NSLog(@"setModels - 转换后数据: %@", _models);
    
    // 使用统一的方法更新空状态视图显示
    [self updateEmptyViewWithData:_models];
    
    // 设置 table 的数据源
    _table.models = _models;
    [_table reloadData];
}

#pragma mark - get
- (TITableView *)table {
    if (!_table) {
        // 直接使用导航栏高度作为起点，不再计算状态栏
        CGFloat topOffset = 0; // 从顶部开始布局
        
        // 创建表格视图并设置正确的尺寸
        _table = [TITableView initWithFrame:CGRectMake(0, topOffset, SCREEN_WIDTH, SCREEN_HEIGHT - self.bottom.height)];
        [_table setDelegate:self];
        [_table setDataSource:self];
        [_table setBackgroundColor:kColor_BG];
        [_table setShowsVerticalScrollIndicator:NO];
        [_table setShowsHorizontalScrollIndicator:NO];
        [_table setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        
        // 设置表格内容偏移以匹配导航栏
        UIEdgeInsets insets = UIEdgeInsetsMake(NavigationBarHeight, 0, 0, 0);
        [_table setContentInset:insets];
        // 设置滚动指示器的偏移
        [_table setScrollIndicatorInsets:insets];
        
        // 禁用自动调整内容边距
        if (@available(iOS 11.0, *)) {
            [_table setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
        } else {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
        
        [_table registerNib:[UINib nibWithNibName:@"TITableCell" bundle:nil] forCellReuseIdentifier:@"TITableCell"];
    }
    return _table;
}

- (BottomButton *)bottom {
    if (!_bottom) {
        NSLog(@"SCREEN_HEIGHT:%f,SCREEN_WIDTH:%f,SafeAreaBottomHeight:%f",SCREEN_HEIGHT,SCREEN_WIDTH,SafeAreaBottomHeight);
        _bottom = [BottomButton initWithFrame:({
            CGFloat height = countcoordinatesX(50) + SafeAreaBottomHeight;
            // old: top = SCREEN_HEIGHT - height
            CGFloat top = SCREEN_HEIGHT - height - NavigationBarHeight;
            CGRectMake(0, top, SCREEN_WIDTH, height);
        })];
        [_bottom setName:@"添加提醒"];
        [self.view addSubview:_bottom];
    }
    _bottom.layer.shadowPath = [UIBezierPath bezierPathWithRect:_bottom.bounds].CGPath;
    return _bottom;
}

- (NSDictionary<NSString *, NSInvocation *> *)eventStrategy {
    if (!_eventStrategy) {
        _eventStrategy = @{
            CATEGORY_BTN_CLICK: [self createInvocationWithSelector:@selector(bottomClick:)],
            TIMING_CELL_DELETE: [self createInvocationWithSelector:@selector(timeCellDelete:)],
        };
    }
    return _eventStrategy;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"numberOfRowsInSection called - models count: %lu", (unsigned long)self.models.count);
    return self.models.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TITableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TITableCell"];
    NSLog(@"cellForRowAtIndexPath called - row: %ld, time: %@", (long)indexPath.row, self.models[indexPath.row]);
    cell.time = self.models[indexPath.row];
    cell.indexPath = indexPath;
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50.0f; // 设置合适的 cell 高度
}

@end
