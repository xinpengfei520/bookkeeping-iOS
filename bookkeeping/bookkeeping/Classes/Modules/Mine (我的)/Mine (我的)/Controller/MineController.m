/**
 * 记账
 * @author 郑业强 2018-12-16 创建文件
 */

#import "MineController.h"
#import "CAController.h"
#import "TimeRemindController.h"
#import "InfoController.h"
#import "LoginController.h"
#import "BillController.h"
#import "MINE_EVENT_MANAGER.h"
#import "LAContextManager.h"
#import "UIViewController+HBD.h"

#define IS_IPHONE_X ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)

#pragma mark - 声明
@interface MineController()

@property (nonatomic, strong) UserModel *model;
@property (nonatomic, strong) NSDictionary<NSString *, NSInvocation *> *eventStrategy;

@end


#pragma mark - 实现
@implementation MineController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = YES;
    [self mine];
    [self setupUI];
}

- (void)setupUI {
    // 登录了
    if ([UserInfo isLogin]) {
        [self getUserInfoRequest];
    }
    // 未登录
    else {
        
    }
}


#pragma mark - 请求
// 获取个人信息
- (void)getUserInfoRequest {
    __unused UserModel *model = [UserInfo loadUserInfo];
    
    @weakify(self)
    [self.afn_request setAfn_useCache:false];
    [AFNManager POST:userInfoRequest params:nil complete:^(APPResult *result) {
        @strongify(self)
        if (result.status == HttpStatusSuccess && result.code == BIZ_SUCCESS) {
            __unused UserModel *userModel = [UserModel mj_objectWithKeyValues:result.data];
            [UserInfo saveUserInfo:result.data];
            [self.mine.table setModel:[UserInfo loadUserInfo]];
        } else {
            [self showTextHUD:result.msg delay:1.f];
        }
    }];
}

#pragma mark - set
// 数据
- (void)setModel:(UserModel *)model {
    _model = model;
    _mine.model = model;
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

// Cell
- (void)mineCellClick:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // 我的账单
        if (indexPath.row == 0) {
            BillController *vc = [[BillController alloc] init];
            [self.navigationController pushViewController:vc animated:true];
        }
        // 类别设置
        if (indexPath.row == 1) {
            CAController *vc = [[CAController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
        // 定时提醒
        else if (indexPath.row == 2) {
            TimeRemindController *vc = [[TimeRemindController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
    else if (indexPath.section == 1) {
        // 同步数据
         if (indexPath.row == 0 && [UserInfo isLogin]) {
            [self.view syncedDataRequest];
        }
    }
}

// 头像
- (void)headerIconClick:(id)data {
    // 登录了
    if ([UserInfo isLogin] == true) {
        InfoController *vc = [[InfoController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
    // 没登录
    else {
        @weakify(self)
        LoginController *vc = [[LoginController alloc] init];
        [vc setComplete:^{
            @strongify(self)
            self.model = [UserInfo loadUserInfo];
        }];
        BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController:vc];
        [self.navigationController presentViewController:nav animated:YES completion:nil];
    }
}

// 连续打卡
- (void)headerPunchClick:(id)data {
    
}

// 记账总天数
- (void)headerDayClick:(id)data {
    InfoController *vc = [[InfoController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

// 记账总笔数
- (void)headerNumberClick:(id)data {
    
}

// FaceID 开关点击事件
- (void)faceIdClick:(NSNumber *)isOn {
    [self verifyFaceID];
}

- (void)verifyFaceID {
    [LAContextManager callLAContextManagerWithController:self success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"FaceID verify success~");
            // 从缓存中取出 PIN_SETTING_FACE_ID 的值，如果没有则默认为 0
            NSNumber *faceId = [NSUserDefaults objectForKey:PIN_SETTING_FACE_ID];
            faceId = @(![faceId boolValue]);
            [NSUserDefaults setObject:faceId forKey:PIN_SETTING_FACE_ID];
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

#pragma mark - get
- (MineView *)mine {
    if (!_mine) {
        _mine = [MineView loadCode:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - TabbarHeight)];
        [self.view addSubview:_mine];
    }
    return _mine;
}

/**
 * 创建点击事件策略
 */
- (NSDictionary<NSString *, NSInvocation *> *)eventStrategy {
    if (!_eventStrategy) {
        _eventStrategy = @{
            MINE_CELL_CLICK: [self createInvocationWithSelector:@selector(mineCellClick:)],
            MINE_HEADER_ICON_CLICK: [self createInvocationWithSelector:@selector(headerIconClick:)],
            MINE_HEADER_PUNCH_CLICK: [self createInvocationWithSelector:@selector(headerPunchClick:)],
            MINE_HEADER_DAY_CLICK: [self createInvocationWithSelector:@selector(headerDayClick:)],
            MINE_HEADER_NUMBER_CLICK: [self createInvocationWithSelector:@selector(headerNumberClick:)],
            MINE_FACE_ID_CLICK: [self createInvocationWithSelector:@selector(faceIdClick:)]
        };
    }
    return _eventStrategy;
}

#pragma mark - 系统
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setModel:[UserInfo loadUserInfo]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}


@end
