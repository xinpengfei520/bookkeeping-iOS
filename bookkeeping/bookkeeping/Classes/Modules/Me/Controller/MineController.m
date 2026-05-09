/**
 * 记账
 * @author 郑业强 2018-12-16 创建文件
 */

#import "MineController.h"
#import "LAContextManager.h"
#import <MessageUI/MessageUI.h>
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface MineController() <MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) UserModel *model;
@property (nonatomic, strong) NSDictionary<NSString *, NSInvocation *> *eventStrategy;

@end


#pragma mark - 实现
@implementation MineController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.prefersNavigationBarHidden = YES;
    [self mine];
    [self setupUI];
    [self setupBackButton];
}

// 个人中心顶部左上角的返回按钮 —— 隐藏导航条页面里手动提供入口，
// 系统侧滑返回也由 BaseViewController 重新接管。
- (void)setupBackButton {
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *icon = [[UIImage imageNamed:@"nav_back_n"]
                     imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [backButton setImage:icon forState:UIControlStateNormal];
    backButton.tintColor = kColor_Text_White;
    [backButton addTarget:self
                   action:@selector(backBtnClick)
         forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
    [self.view bringSubviewToFront:backButton];
    [backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(8);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(4);
        make.width.height.equalTo(@44);
    }];
}

- (void)backBtnClick {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setupUI {
    // 登录了
    if ([UserInfo isLogin]) {
        [self getUserInfoRequest];
        // 同步数据
        //[self.view syncedDataRequest];
    }
    // 未登录
    else {
        
    }
}


#pragma mark - 请求
// 获取个人信息
- (void)getUserInfoRequest {
    @weakify(self)
    [self.afn_request setAfn_useCache:false];
    [AFNManager POST:userInfoRequest params:nil complete:^(APPResult *result) {
        @strongify(self)
        if (result.status == HttpStatusSuccess && result.code == BIZ_SUCCESS) {
            [UserInfo saveUserInfo:result.data];
            self.model = [UserModel mj_objectWithKeyValues:result.data];
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
    }
    else if (indexPath.section == 1) {
        // 类别设置
        if (indexPath.row == 0) {
            CAController *vc = [[CAController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
        // 定时提醒
        else if (indexPath.row == 1) {
            TimeRemindController *vc = [[TimeRemindController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
        // 导出数据
        else if (indexPath.row == 3) {
            ExportController *vc = [[ExportController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
        // 语言
        else if (indexPath.row == 4) {
            LanguageSettingsController *vc = [[LanguageSettingsController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
        // 深色模式
        else if (indexPath.row == 5) {
            ThemeSettingsController *vc = [[ThemeSettingsController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
    else if (indexPath.section == 2) {
        // 邀请好友
        if (indexPath.row == 0) {
            [self inviteFriendsClick];
        }
        // 意见反馈
        else if (indexPath.row == 1) {
            [self feedbackClick];
        }
        // 帮助
        else if (indexPath.row == 2) {
            WebViewController *vc = [[WebViewController alloc] init];
            vc.title = KKLocalized(@"帮助");
            [vc setUrl:kHelpURL];
            [self.navigationController pushViewController:vc animated:YES];
        }
        // 关于
        else if (indexPath.row == 3) {
            AboutController *vc = [[AboutController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
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
            [self getUserInfoRequest];
        }];
        BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController:vc];
        [self.navigationController presentViewController:nav animated:YES completion:nil];
    }
}

// 记账总天数、笔数
- (void)headerNumberClick:(id)data {
    ShareController *vc = [[ShareController alloc] init];
    vc.model = _model;
    [self.navigationController pushViewController:vc animated:YES];
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
        _mine = [MineView loadCode:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
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
            MINE_HEADER_DAY_CLICK: [self createInvocationWithSelector:@selector(headerNumberClick:)],
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

#pragma mark - 意见反馈
- (void)feedbackClick {
    // 准备邮件内容
    NSString *toEmail = @"542270559@qq.com";
    NSString *subject = KKLocalized(@"记呀 - 意见反馈");
    
    // 获取设备信息
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    NSString *deviceModel = [[UIDevice currentDevice] model];
    
    NSString *body = [NSString stringWithFormat:@"\n\n\n\n\n\n"
                     @"----------\n"
                     KKLocalized(@"App版本：%@\n")
                     KKLocalized(@"系统版本：iOS %@\n")
                     KKLocalized(@"设备型号：%@\n"),
                     appVersion, systemVersion, deviceModel];
    
    // URL 编码
    subject = [subject stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    body = [body stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    // 构造邮件 URL
    NSString *mailtoUrl = [NSString stringWithFormat:@"mailto:%@?subject=%@&body=%@", 
                          toEmail, subject, body];
    
    NSURL *url = [NSURL URLWithString:mailtoUrl];
    
    // 检查是否可以打开邮件
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:url 
                                            options:@{} 
                                  completionHandler:^(BOOL success) {
                if (!success) {
                    [self showTextHUD:KKLocalized(@"无法打开邮件应用") delay:2.f];
                }
            }];
        } else {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [[UIApplication sharedApplication] openURL:url];
            #pragma clang diagnostic pop
        }
    } else {
        [self showTextHUD:KKLocalized(@"设备不支持发送邮件") delay:2.f];
    }
}

// 移除不需要的代理方法
- (void)mailComposeController:(MFMailComposeViewController *)controller 
          didFinishWithResult:(MFMailComposeResult)result 
                        error:(NSError *)error {
    // 移除这个方法
}

#pragma mark - 邀请好友
- (void)inviteFriendsClick {
    // 准备分享内容
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"] ?: KKLocalized(@"记呀");
    NSString *text = [NSString stringWithFormat:KKLocalized(@"推荐一个好用的记账App：%@"), appName];
    UIImage *image = [UIImage imageNamed:@"AppPreview"];
    NSURL *appUrl = [NSURL URLWithString:kAppStoreURL];
    
    // 创建分享内容
    NSArray *activityItems = @[];
    if (text) {
        activityItems = [activityItems arrayByAddingObject:text];
    }
    if (image) {
        activityItems = [activityItems arrayByAddingObject:image];
    }
    if (appUrl) {
        activityItems = [activityItems arrayByAddingObject:appUrl];
    }
    
    // 创建分享控制器
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems 
                                                                           applicationActivities:nil];
    
    // 设置回调
    activityVC.completionWithItemsHandler = ^(UIActivityType activityType, 
                                            BOOL completed, 
                                            NSArray *returnedItems, 
                                            NSError *activityError) {
        if (completed) {
            [self showTextHUD:KKLocalized(@"分享成功") delay:2.f];
        }
    };
    
    // 在 iPad 上需要设置弹出位置
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        activityVC.popoverPresentationController.sourceView = self.view;
        activityVC.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width/2, 
                                                                        self.view.bounds.size.height/2, 
                                                                        0, 
                                                                        0);
    }
    
    [self presentViewController:activityVC animated:YES completion:nil];
}
@end
