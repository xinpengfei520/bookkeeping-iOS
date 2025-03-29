/**
 * 个人信息
 * @author 郑业强 2018-12-22 创建文件
 */

#import "InfoController.h"
#import "InfoTableView.h"
#import "AlertViewManager.h"
#import "DeleteAccountController.h"

#pragma mark - 声明
@interface InfoController()

@property (nonatomic, strong) InfoTableView *table;
@property (nonatomic, strong) UserModel *model;
// 临时保存修改后的用户信息
@property (nonatomic, strong) UserModel *updateModel;
@property (nonatomic, strong) NSDictionary<NSString *, NSInvocation *> *eventStrategy;

@end


#pragma mark - 实现
@implementation InfoController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = NO;
    self.hbd_barTintColor = kColor_Main_Color;
    [self setNavTitle:@"个人信息"];
    [self.view setBackgroundColor:kColor_Line_Color];
    [self table];
    [self setModel:[UserInfo loadUserInfo]];
    [self setUpdateModel:[UserInfo loadUserInfo]];
}


#pragma mark - request
- (void)changeIconRequest:(UIImage *)image {
    @weakify(self)
    [self.afn_request setAfn_useCache:false];
    [self showProgressHUD:@"修改中"];
    [AFNManager POST:uploadAvatarRequest params:nil images:@[image] progress:nil complete:^(APPResult *result) {
        @strongify(self)
        [self hideHUD];
        if (result.status == HttpStatusSuccess && result.code == BIZ_SUCCESS) {
            // 取出上传成功后的 url
            NSDictionary *dic = [[NSDictionary alloc]initWithDictionary:result.data];
            NSString *avatarUrl = [dic objectForKey:@"avatarUrl"];
            
            [self.updateModel setUserAvatar:avatarUrl];
            [UserInfo saveUserModel:self.updateModel];
            [self setModel:self.updateModel];
            [self.table reloadData];
        } else {
            [self showTextHUD:result.msg delay:1.f];
        }
    }];
}

- (void)logoutRequest {
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

- (void)changePhoneRequest:(NSString *)phone {
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    [param setObject:phone forKey:@"userName"];
    [self.updateModel setUserName:phone];
    [self changeUserInfoRequest:param];
}

- (void)changeNickRequest:(NSString *)nickName {
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    [param setObject:nickName forKey:@"nickname"];
    [self.updateModel setNickname:nickName];
    [self changeUserInfoRequest:param];
}

- (void)changeSexRequest:(NSInteger)sex {
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    [param setObject:@(sex) forKey:@"sex"];
    [self.updateModel setSex:sex];
    [self changeUserInfoRequest:param];
}

- (void)changeUserInfoRequest:(NSMutableDictionary *)param {
    @weakify(self)
    [self.afn_request setAfn_useCache:false];
    [self showProgressHUD:@"修改中"];
    [AFNManager POST:updateUserInfoRequest params:param complete:^(APPResult *result) {
        @strongify(self)
        [self hideHUD];
        if (result.status == HttpStatusSuccess && result.code == BIZ_SUCCESS) {
            [self showTextHUD:@"修改成功" delay:1.f];
            // 更新数据
            [UserInfo saveUserModel:self.updateModel];
            [self setModel:self.updateModel];
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
        // 邮箱
        else if (indexPath.row == 5) {
            [self updateEmail];
        }
    } else if (indexPath.section == 1) {
        // 修改密码
        PasswordController *vc = [[PasswordController alloc] init];
        [self.navigationController pushViewController:vc animated:true];
    } else if (indexPath.section == 2) {
        // 删除账号
        DeleteAccountController *vc = [[DeleteAccountController alloc] init];
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
            [self logoutRequest];
        }
    } buttonArray:buttonArray];
}

// 拍照
- (void)takePhoto {
    [[AlertViewManager sharedInstacne]showSheet:nil message:nil cancelTitle:@"取消" viewController:self confirm:^(NSInteger buttonTag,NSString *buttonTitle) {
        
        [ZLPhotoConfiguration default].allowSelectVideo = NO;
        [ZLPhotoConfiguration default].maxVideoSelectCount = 0;
        [ZLPhotoConfiguration default].allowSelectGif = NO;
        [ZLPhotoConfiguration default].maxSelectCount = 1;
        
        // 拍照
        if (buttonTag == 0) {
            @weakify(self)
            ZLCameraConfiguration *cameraConfig = [ZLPhotoConfiguration default].cameraConfiguration;
            // All properties of the camera configuration have default value
            cameraConfig.sessionPreset = CaptureSessionPresetVga640x480;
            cameraConfig.focusMode = FocusModeContinuousAutoFocus;
            cameraConfig.exposureMode = ExposureModeContinuousAutoExposure;
            //cameraConfig.exposureMode = FlashModeOff;
            cameraConfig.videoExportType = VideoExportTypeMov;

            ZLCustomCamera *camera = [[ZLCustomCamera alloc] init];
            camera.takeDoneBlock = ^(UIImage * _Nullable image, NSURL * _Nullable videoUrl) {
                @strongify(self)
                [self changeIconRequest:image];
            };
            [self showDetailViewController:camera sender:nil];
        }
        // 从相册选择
        else if (buttonTag == 1) {
            @weakify(self)
            ZLPhotoPreviewSheet *ps = [[ZLPhotoPreviewSheet alloc] initWithSelectedAssets:@[]];
            ps.selectImageBlock = ^(NSArray<UIImage *> * _Nonnull images, BOOL isOriginal) {
                @strongify(self)
                [self changeIconRequest:images[0]];
            };
            [ps showPhotoLibraryWithSender:self];
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

// 更新邮箱
- (void)updateEmail {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"修改邮箱" message:nil preferredStyle:UIAlertControllerStyleAlert];
    // 增加取消按钮
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
    // 增加确定按钮
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
        // 获取输入框内容
        UITextField *emailTextField = alertController.textFields.firstObject;
        if (emailTextField.text.length == 0) {
            [self showTextHUD:@"邮箱不能为空" delay:1.f];
            return;
        }
        
        // 验证邮箱格式
        NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        if (![emailTest evaluateWithObject:emailTextField.text]) {
            [self showTextHUD:@"邮箱格式不正确" delay:1.f];
            return;
        }
        
        [self changeEmailRequest:emailTextField.text];
    }]];
    // 添加输入框
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入邮箱地址";
        textField.keyboardType = UIKeyboardTypeEmailAddress;
        // 如果已有邮箱，预先填入
        if (self.model.email && self.model.email.length > 0) {
            textField.text = self.model.email;
        }
    }];
    [self presentViewController:alertController animated:true completion:nil];
}

// 修改邮箱请求
- (void)changeEmailRequest:(NSString *)email {
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    [param setObject:email forKey:@"email"];
    [self.updateModel setEmail:email];
    [self changeUserInfoRequest:param];
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
