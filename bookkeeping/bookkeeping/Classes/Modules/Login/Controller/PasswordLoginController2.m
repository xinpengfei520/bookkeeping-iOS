#import "PasswordLoginController2.h"
#import <Masonry/Masonry.h>
#import "AgreementView.h"

@interface PasswordLoginController2() <AgreementViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIView *inputBgView;
@property (nonatomic, strong) AgreementView *agreementView;
@property (nonatomic, strong) UIButton *passwordVisibilityButton;

@end

@implementation PasswordLoginController2

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = YES;
    [self.view setBackgroundColor:kColor_BG];
    [self setupUI];
    
    // 延迟一小段时间后自动弹出键盘，确保视图已经完全加载
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.passwordField becomeFirstResponder];
    });
}

- (void)setupUI {
    // 标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"密码登录";
    titleLabel.font = [UIFont systemFontOfSize:32];
    [self.view addSubview:titleLabel];
    
    // 关闭按钮
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton setImage:[UIImage imageNamed:@"login_close"] forState:UIControlStateNormal];
    [closeButton setImage:[UIImage imageNamed:@"login_close_h"] forState:UIControlStateHighlighted];
    [closeButton addTarget:self action:@selector(closeBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    // 手机号显示
    UILabel *phoneLabel = [[UILabel alloc] init];
    NSMutableString *formattedPhone = [NSMutableString stringWithString:self.phone];
    if (formattedPhone.length == 11) {
        [formattedPhone insertString:@" " atIndex:7];
        [formattedPhone insertString:@" " atIndex:3];
    }
    phoneLabel.text = [NSString stringWithFormat:@"+86 %@", formattedPhone];
    phoneLabel.font = [UIFont systemFontOfSize:14];
    phoneLabel.textColor = [UIColor lightGrayColor];
    [self.view addSubview:phoneLabel];
    
    // 输入框背景
    _inputBgView = [[UIView alloc] init];
    _inputBgView.backgroundColor = [UIColor whiteColor];
    _inputBgView.layer.cornerRadius = 8;
    _inputBgView.layer.borderWidth = 1;
    _inputBgView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [self.view addSubview:_inputBgView];
    
    // 密码输入框
    _passwordField = [[UITextField alloc] init];
    _passwordField.placeholder = @"请输入密码";
    _passwordField.font = [UIFont systemFontOfSize:14];
    _passwordField.secureTextEntry = YES;
    [_passwordField addTarget:self action:@selector(textFieldDidEditing:) forControlEvents:UIControlEventEditingChanged];
    [_inputBgView addSubview:_passwordField];
    
    // 添加密码显示/隐藏按钮
    _passwordVisibilityButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_passwordVisibilityButton setImage:[self tintImage:[UIImage imageNamed:@"icon_pwd_hide"] withColor:kColor_Main_Color] forState:UIControlStateNormal];
    [_passwordVisibilityButton setImage:[self tintImage:[UIImage imageNamed:@"icon_pwd_show"] withColor:kColor_Main_Color] forState:UIControlStateSelected];
    [_passwordVisibilityButton addTarget:self action:@selector(togglePasswordVisibility:) forControlEvents:UIControlEventTouchUpInside];
    _passwordVisibilityButton.hidden = YES;  // 默认隐藏
    [_inputBgView addSubview:_passwordVisibilityButton];
    
    // 登录按钮
    _loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_loginButton setTitle:@"登录" forState:UIControlStateNormal];
    [_loginButton addTarget:self action:@selector(loginButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_loginButton];
    [self buttonCanTap:NO btn:_loginButton];
    
    // 添加协议视图
    _agreementView = [[AgreementView alloc] initWithShowRegisterTips:NO];
    _agreementView.delegate = self;
    _agreementView.isSelected = YES;
    [self.view addSubview:_agreementView];
    
    [_agreementView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(_loginButton.mas_bottom).offset(16);
        make.height.equalTo(@44);
        make.width.greaterThanOrEqualTo(@200);
    }];
    
    // 设置约束
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16);
        make.top.equalTo(self.view).offset(90);
    }];
    
    [closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(10);
        make.left.equalTo(self.view).offset(16);
        make.width.height.equalTo(@40);
    }];
    
    [phoneLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16);
        make.top.equalTo(titleLabel.mas_bottom).offset(32);
    }];
    
    [_inputBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.top.equalTo(phoneLabel.mas_bottom).offset(16);
        make.height.equalTo(@55);
    }];
    
    [_passwordField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_inputBgView).offset(16);
        make.right.equalTo(_passwordVisibilityButton.mas_left).offset(-8);
        make.centerY.equalTo(_inputBgView);
    }];
    
    [_passwordVisibilityButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_inputBgView).offset(-16);
        make.centerY.equalTo(_inputBgView);
        make.width.height.equalTo(@24);
    }];
    
    [_loginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.top.equalTo(_inputBgView.mas_bottom).offset(16);
        make.height.equalTo(@50);
    }];
    
    _passwordField.delegate = self;
}

#pragma mark - Actions
- (void)closeBtnClick {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)loginButtonClick {
    [self showProgressHUD];
    NSDictionary *params = @{
        @"loginType": @"password",
        @"phone": [self.phone stringByReplacingOccurrencesOfString:@" " withString:@""],
        @"password": self.passwordField.text
    };
    
    [AFNManager POST:userLoginRequest params:params complete:^(APPResult *result) {
        [self hideHUD];
        if (result.status == HttpStatusSuccess && result.code == BIZ_SUCCESS) {
            if (self.complete) {
                self.complete();
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:USER_LOGIN_COMPLETE object:nil];
        } else {
            [self showTextHUD:result.msg delay:1.5f];
        }
    }];
}

#pragma mark - Helper
- (void)buttonCanTap:(BOOL)tap btn:(UIButton *)btn {
    if (tap) {
        [btn setUserInteractionEnabled:YES];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [btn setTitleColor:kColor_Text_White forState:UIControlStateNormal];
        [btn setBackgroundImage:[UIColor createImageWithColor:kColor_Main_Color] forState:UIControlStateNormal];
        [btn setBackgroundImage:[UIColor createImageWithColor:kColor_Main_Dark_Color] forState:UIControlStateHighlighted];
    } else {
        [btn setUserInteractionEnabled:NO];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [btn setTitleColor:kColor_Text_Gary forState:UIControlStateNormal];
        [btn setBackgroundImage:[UIColor createImageWithColor:kColor_Line_Color] forState:UIControlStateNormal];
    }
    [btn.layer setCornerRadius:8];
    [btn.layer setMasksToBounds:YES];
}

- (void)textFieldDidEditing:(UITextField *)textField {
    // 更新密码显示/隐藏按钮的显示状态
    _passwordVisibilityButton.hidden = (textField.text.length == 0);
    
    // 根据密码长度和协议选中状态设置按钮是否可点击
    if (textField.text.length >= 6) {
        [self buttonCanTap:self.agreementView.isSelected btn:self.loginButton];
    } else {
        [self buttonCanTap:false btn:self.loginButton];
    }
}

- (void)agreementViewDidChangeState:(BOOL)isSelected {
    [self buttonCanTap:isSelected && self.passwordField.text.length >= 6 btn:self.loginButton];
}

#pragma mark - AgreementViewDelegate
- (void)agreementViewDidTapUserAgreement {
    WebViewController *vc = [[WebViewController alloc] init];
    [vc setNavTitle:@"用户协议"];
    [vc setUrl:@"https://book.vance.xin/agreement.html"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)agreementViewDidTapPrivacyAgreement {
    WebViewController *vc = [[WebViewController alloc] init];
    [vc setNavTitle:@"隐私协议"];
    [vc setUrl:@"https://book.vance.xin/privacy.html"];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Actions
- (void)togglePasswordVisibility:(UIButton *)sender {
    sender.selected = !sender.selected;
    _passwordField.secureTextEntry = !sender.selected;
}

- (UIImage *)tintImage:(UIImage *)image withColor:(UIColor *)color {
    UIImage *newImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIGraphicsBeginImageContextWithOptions(image.size, NO, newImage.scale);
    [color set];
    [newImage drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

// 添加输入框开始编辑的代理方法
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // 当开始编辑时，根据是否有内容决定是否显示按钮
    _passwordVisibilityButton.hidden = (textField.text.length == 0);
}

// 添加输入框结束编辑的代理方法
- (void)textFieldDidEndEditing:(UITextField *)textField {
    // 当结束编辑时，根据是否有内容决定是否显示按钮
    _passwordVisibilityButton.hidden = (textField.text.length == 0);
}

@end 
