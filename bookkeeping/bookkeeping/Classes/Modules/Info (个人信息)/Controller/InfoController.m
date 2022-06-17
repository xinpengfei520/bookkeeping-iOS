/**
 * 个人信息
 * @author 郑业强 2018-12-22 创建文件
 */

#import "InfoController.h"
#import "InfoTableView.h"
#import "CPAController.h"
#import "INFO_EVENT_MANAGER.h"
#import "LOGIN_NOTIFICATION.h"
#import "UIViewController+HBD.h"
#import "AlertViewManager.h"

#pragma mark - 声明
@interface InfoController()

@property (nonatomic, strong) InfoTableView *table;
@property (nonatomic, strong) UserModel *model;
@property (nonatomic, strong) NSDictionary<NSString *, NSInvocation *> *eventStrategy;

@end


#pragma mark - 实现
@implementation InfoController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNavTitle:@"个人信息"];
    self.hbd_barHidden = NO;
    self.hbd_barTintColor = kColor_Main_Color;
    [self.view setBackgroundColor:kColor_Line_Color];
    [self table];
    [self setModel:[UserInfo loadUserInfo]];
}


#pragma mark - request
- (void)changeIconRequest:(UIImage *)image {
    @weakify(self)
    UserModel *model = [UserInfo loadUserInfo];
    NSMutableDictionary *param = ({
        NSMutableDictionary *param = [NSMutableDictionary dictionary];
        if (model.userId) {
            [param setObject:model.userId forKey:@"account"];
        }
        param;
    });
    [self.afn_request setAfn_useCache:false];
    [self showProgressHUD:@"修改中"];
    [AFNManager POST:ChangeIconRequest params:param andImages:@[image] progress:nil complete:^(APPResult *result) {
        @strongify(self)
        [self hideHUD];
        if (result.status == HttpStatusSuccess) {
            // 更新数据
            UserModel *model = [UserInfo loadUserInfo];
            [model setUserAvatar:result.data];
            [UserInfo saveUserModel:model];
            [self setModel:model];
            // 刷新
            [self.table reloadData];
        } else {
            [self showTextHUD:result.msg delay:1.f];
        }
    }];
}

- (void)sendLogoutRequest {
    @weakify(self)
    [self.afn_request setAfn_useCache:false];
    [AFNManager POST:userLogoutRequest params:nil complete:^(APPResult *result) {
        @strongify(self)
        if (result.status == HttpStatusSuccess && result.code == BIZ_SUCCESS) {
            [UserInfo clearUserInfo];
            [self.navigationController popViewControllerAnimated:true];
            [[NSNotificationCenter defaultCenter] postNotificationName:USER_LOGOUT_COMPLETE object:nil];
        } else {
            [self showTextHUD:result.msg delay:1.f];
        }
    }];
}

- (void)changePhoneRequest:(NSString *)nickName {
    
}

- (void)changeNickRequest:(NSString *)nickName {
    @weakify(self)
    UserModel *model = [UserInfo loadUserInfo];
    NSMutableDictionary *param = ({
        NSMutableDictionary *param = [NSMutableDictionary dictionary];
        [param setObject:nickName forKey:@"name"];
        if (model.userId) {
            [param setObject:model.userId forKey:@"account"];
        }
        param;
    });
    [self.afn_request setAfn_useCache:false];
    [self showProgressHUD:@"修改中"];
    [AFNManager POST:NicknameRequest params:param complete:^(APPResult *result) {
        @strongify(self)
        [self hideHUD];
        if (result.status == HttpStatusSuccess) {
            // 更新数据
            UserModel *model = [UserInfo loadUserInfo];
            [model setUserName:nickName];
            [UserInfo saveUserModel:model];
            [self setModel:model];
        } else {
            [self showTextHUD:result.msg delay:1.f];
        }
    }];
}

- (void)changeSexRequest:(NSInteger)sex {
    @weakify(self)
    UserModel *model = [UserInfo loadUserInfo];
    NSMutableDictionary *param = ({
        NSMutableDictionary *param = [NSMutableDictionary dictionary];
        [param setObject:@(sex) forKey:@"sex"];
        if (model.userId) {
            [param setObject:model.userId forKey:@"userId"];
        }
        param;
    });
    [self.afn_request setAfn_useCache:false];
    [self showProgressHUD:@"修改中"];
    [AFNManager POST:ChangeSexRequest params:param complete:^(APPResult *result) {
        @strongify(self)
        [self hideHUD];
        if (result.status == HttpStatusSuccess) {
            // 更新数据
            UserModel *model = [UserInfo loadUserInfo];
            [UserInfo saveUserModel:model];
            [self setModel:model];
            // 刷新
            [self.table reloadData];
        } else {
            [self showTextHUD:result.msg delay:1.f];
        }
    }];
}


#pragma mark - set
- (void)setModel:(UserModel *)model {
    _model = model;
    _table.model = model;
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

// 点击cell
- (void)cellClick:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // 拍照
        if (indexPath.row == 0) {
            [self takePhoto];
        }
        // 昵称
        else if (indexPath.row == 2) {
            [self takeNickname];
        }
        // 性别
        else if (indexPath.row == 3) {
            [self takeSex];
        }
        // 手机号
        else if (indexPath.row == 4) {
            [self updatePhone];
        }
        // QQ
        else if (indexPath.row == 5) {
            
        }
    } else {
        CPAController *vc = [[CPAController alloc] init];
        [self.navigationController pushViewController:vc animated:true];
    }
}

// 退出登录
- (void)logoutClick:(id)data {
    // 按钮二维数组，array[0] 存放 title 数组, array[1] 存放 style 数组
    NSArray<NSArray *> *buttonArray = @[
        @[@"退出登录"],
        @[[NSNumber numberWithInteger:UIAlertActionStyleDestructive]]
    ];
    
    [[AlertViewManager sharedInstacne]showSheet:@"记呀" message:@"确定退出当前帐号吗？" cancelTitle:@"取消" viewController:self confirm:^(NSInteger buttonTag,NSString *buttonTitle) {
        if (buttonTag == 0) {
            [self sendLogoutRequest];
        }
    } buttonArray:buttonArray];
}

// 拍照
- (void)takePhoto {
    [[AlertViewManager sharedInstacne]showSheet:nil message:nil cancelTitle:@"取消" viewController:self confirm:^(NSInteger buttonTag,NSString *buttonTitle) {
        // 拍照
        if (buttonTag == 0) {
            
        }
        // 从相册选择
        else if (buttonTag == 1) {
            
        }
    } buttonTitles:@"拍照", @"从相册选择", nil];
}

// 性别
- (void)takeSex {
    [[AlertViewManager sharedInstacne]showSheet:nil message:nil cancelTitle:@"取消" viewController:self confirm:^(NSInteger buttonTag,NSString *buttonTitle) {
        if (buttonTag == 0) {
            [self changeSexRequest:1];
        } else if (buttonTag == 1) {
            [self changeSexRequest:0];
        }
    } buttonTitles:@"男", @"女", nil];
}

// 昵称
- (void)takeNickname {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"修改昵称" message:nil preferredStyle:UIAlertControllerStyleAlert];
    // 增加取消按钮；
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
    // 增加确定按钮
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
        // 获取第1个输入框；
        UITextField *titleTextField = alertController.textFields.firstObject;
        NSLog(@"%@", titleTextField.text);
        if (titleTextField.text.length == 0) {
            [self showTextHUD:@"昵称不能为空" delay:1.f];
            return;
        }
        [self changeNickRequest:titleTextField.text];
    }]];
    // 定义第一个输入框；
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入2-8位昵称";
        [textField addTarget:self action:@selector(txtValueChange:) forControlEvents:UIControlEventEditingChanged];
    }];
    [self presentViewController:alertController animated:true completion:nil];
}

- (void)updatePhone {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"修改手机号" message:nil preferredStyle:UIAlertControllerStyleAlert];
    // 增加取消按钮；
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
    // 增加确定按钮
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
        // 获取第1个输入框；
        UITextField *titleTextField = alertController.textFields.firstObject;
        NSLog(@"%@", titleTextField.text);
        if (titleTextField.text.length == 0) {
            [self showTextHUD:@"手机号不能为空" delay:1.f];
            return;
        }
        [self changePhoneRequest:titleTextField.text];
    }]];
    // 定义第一个输入框；
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入11位新手机号";
        [textField addTarget:self action:@selector(inputPhoneChange:) forControlEvents:UIControlEventEditingChanged];
    }];
    [self presentViewController:alertController animated:true completion:nil];
}

- (void)txtValueChange:(UITextField *)textField {
    if (textField.text.length > 8) {
        textField.text = [textField.text substringToIndex:8];
    }
}

- (void)inputPhoneChange:(UITextField *)textField {
    if (textField.text.length > 11) {
        textField.text = [textField.text substringToIndex:11];
    }
}

#pragma mark - get
- (InfoTableView *)table {
    if (!_table) {
        _table = [[InfoTableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - NavigationBarHeight) style:UITableViewStylePlain];
        [self.view addSubview:_table];
    }
    return _table;
}

- (NSDictionary<NSString *, NSInvocation *> *)eventStrategy {
    if (!_eventStrategy) {
        _eventStrategy = @{
            INFO_CELL_CLICK: [self createInvocationWithSelector:@selector(cellClick:)],
            INFO_FOOTER_CLICK: [self createInvocationWithSelector:@selector(logoutClick:)],
        };
    }
    return _eventStrategy;
}


@end
