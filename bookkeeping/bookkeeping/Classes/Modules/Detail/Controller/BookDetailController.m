/**
 * 记账详情页
 * @author 郑业强 2019-01-05 创建
 */

#import "BookDetailController.h"
#import "BDHeader.h"
#import "BDTable.h"
#import "BDBottom.h"

#pragma mark - 声明
@interface BookDetailController()

@property (nonatomic, strong) BDHeader *header;
@property (nonatomic, strong) BDTable *table;
@property (nonatomic, strong) BDBottom *bottom;
@property (nonatomic, strong) NSDictionary<NSString *, NSInvocation *> *eventStrategy;

@end


#pragma mark - 实现
@implementation BookDetailController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = YES;
    [self.rightButton setHidden:YES];
    [self header];
    [self bottom];
    [self table];
    [self monitorNotification];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// 监听通知
- (void)monitorNotification {
    @weakify(self)
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:NOTIFICATION_BOOK_UPDATE object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(NSNotification *x) {
        @strongify(self)
        BookDetailModel *model = x.object;
        [self setModel:model];
        if (self.refresh) {
            self.refresh();
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_BOOK_UPDATE_HOME object:model];
    }];
}


#pragma mark - set
- (void)setModel:(BookDetailModel *)model {
    _model = model;
    self.header.model = model;
    self.table.model = model;
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


#pragma mark - 点击
// 点击按钮
- (void)bdBottomClick:(NSNumber *)number {
    // 编辑
    if ([number integerValue] == 0) {
        BookController *vc = [[BookController alloc] init];
        vc.model = _model;
        [self.navigationController pushViewController:vc animated:true];
    }
    // 删除
    else if ([number integerValue] == 1) {
        // 通知
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_BOOK_DELETE object:_model];
        // 返回
        [self.navigationController popViewControllerAnimated:true];
        // 回调
        if (self.complete) {
            self.complete();
        }
    }
}


#pragma mark - get
- (BDHeader *)header {
    if (!_header) {
        _header = [BDHeader loadFirstNib:CGRectMake(0, 0, SCREEN_WIDTH, NavigationBarHeight + 90)];
        [self.view addSubview:_header];
    }
    return _header;
}

- (BDTable *)table {
    if (!_table) {
        _table = [[BDTable alloc] initWithFrame:CGRectMake(0, _header.bottom, SCREEN_WIDTH, SCREEN_HEIGHT - _bottom.height - _header.height) style:UITableViewStylePlain];
        [self.view addSubview:_table];
    }
    return _table;
}

- (BDBottom *)bottom {
    if (!_bottom) {
        _bottom = [BDBottom loadFirstNib:({
            CGFloat height = countcoordinatesX(50) + SafeAreaBottomHeight;
            CGRectMake(0, SCREEN_HEIGHT - height, SCREEN_WIDTH, height);
        })];
        [self.view addSubview:_bottom];
    }
    return _bottom;
}

- (NSDictionary<NSString *, NSInvocation *> *)eventStrategy {
    if (!_eventStrategy) {
        _eventStrategy = @{
            BD_BOTTOM_CLICK: [self createInvocationWithSelector:@selector(bdBottomClick:)],
        };
    }
    return _eventStrategy;
}


@end
