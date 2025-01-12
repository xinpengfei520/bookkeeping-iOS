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
    // 获取所有本地通知数组
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
        NSLog(@"getPendingNotification: %@", requests);
        for (UNNotificationRequest *request in requests) {
            NSString *identifier = request.identifier;
            // 如果找到需要取消的通知，则取消
            if ([identifier isEqualToString:time]) {
                [center removePendingNotificationRequestsWithIdentifiers:@[identifier]];
                NSLog(@"定时提醒通知取消成功");
                break;
            }
        }
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"viewDidLoad - 开始");
    self.hbd_barHidden = NO;
    self.hbd_barTintColor = kColor_Main_Color;
    
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

// 删除cell
- (void)timeCellDelete:(TITableCell *)cell {
    [self deleteTimingRequest:cell.time];
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
    
    // 更新空状态视图显示
    BOOL isEmpty = (_models == nil || _models.count == 0);
    NSLog(@"setModels - isEmpty: %d, models count: %lu", isEmpty, (unsigned long)_models.count);
    [_emptyView setHidden:!isEmpty];
    
    // 设置 table 的数据源
    _table.models = _models;
    [_table reloadData];
}

#pragma mark - get
- (TITableView *)table {
    if (!_table) {
        _table = [TITableView initWithFrame:CGRectMake(0, NavigationBarHeight, SCREEN_WIDTH, SCREEN_HEIGHT - NavigationBarHeight - self.bottom.height)];
        [_table setDelegate:self];
        [_table setDataSource:self];
        [_table setBackgroundColor:kColor_BG];
        [_table setShowsVerticalScrollIndicator:NO];
        [_table setShowsHorizontalScrollIndicator:NO];
        [_table setSeparatorStyle:UITableViewCellSeparatorStyleNone];
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
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50.0f; // 设置合适的 cell 高度
}

- (void)routerWithEventName:(NSString *)eventName data:(id)data {
    if ([eventName isEqualToString:TIMING_CELL_DELETE]) {
        NSIndexPath *indexPath = data;
        // 从数据源中移除
        [self.models removeObjectAtIndex:indexPath.row];
        // 更新 UserDefaults
        [NSUserDefaults setObject:self.models forKey:PIN_TIMING];
        // 刷新表格
        [self.table reloadData];
        // 检查是否需要显示空状态
        [self.emptyView setHidden:self.models.count > 0];
    }
}

@end
