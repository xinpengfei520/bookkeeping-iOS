/**
 * 我的 - 定时提醒
 * @author 郑业强 2018-12-18 创建文件
 */

#import "TimeRemindController.h"
#import "TITableView.h"
#import "BottomButton.h"
#import "TIModel.h"
#import "TITableCell.h"
#import "CA_EVENT.h"
#import "TIMING_EVENT.h"
#import "UIViewController+HBD.h"

#pragma mark - 声明
@interface TimeRemindController()<UNUserNotificationCenterDelegate>

@property (nonatomic, strong) TITableView *table;
@property (nonatomic, strong) BottomButton *bottom;
@property (nonatomic, strong) NSMutableArray *models;
@property (nonatomic, strong) NSDictionary<NSString *, NSInvocation *> *eventStrategy;

@end

#pragma mark - 实现
@implementation TimeRemindController


#pragma mark - UNUserNotificationCenterDelegate
// iOS 10收到通知
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler  API_AVAILABLE(ios(10.0)) {
    
    NSDictionary *userInfo = notification.request.content.userInfo;
    if (@available(iOS 10.0, *)) {
        UNNotificationRequest *request = notification.request;
        UNNotificationContent *content = request.content; // 收到推送的消息内容
        NSNumber *badge = content.badge;  // 推送消息的角标
        NSString *body = content.body;    // 推送消息体
        UNNotificationSound *sound = content.sound;  // 推送消息的声音
        NSString *subtitle = content.subtitle;  // 推送消息的副标题
        NSString *title = (NSString *)content.title;  // 推送消息的标题
        
        if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
            NSLog(@"iOS10 前台收到远程通知:%@", body);
            
        } else {
            // 判断为本地通知
            NSLog(@"iOS10 前台收到本地通知:{\\\\nbody:%@，\\\\ntitle:%@,\\\\nsubtitle:%@,\\\\nbadge：%@，\\\\nsound：%@，\\\\nuserInfo：%@\\\\n}",body,title,subtitle,badge,sound,userInfo);
        }
        completionHandler(UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionSound|UNNotificationPresentationOptionAlert); // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以设置
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
    [self setNavTitle:@"定时提醒"];
    self.hbd_barHidden = NO;
    self.hbd_barTintColor = kColor_Main_Color;
    [self table];
    [self bottom];
    [self.view bringSubviewToFront:self.bottom];
    [self setModels:[NSUserDefaults objectForKey:PIN_TIMING]];
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
- (void)setModels:(NSMutableArray *)models {
    _models = models;
    _table.models = models;
}

#pragma mark - get
- (TITableView *)table {
    if (!_table) {
        // old: y=NavigationBarHeight
        _table = [TITableView initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - NavigationBarHeight - self.bottom.height)];
        [self.view addSubview:_table];
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

@end
