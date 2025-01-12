/**
 * 手机登录
 * @author 郑业强 2018-12-23 创建文件
 */

#import "LoginController.h"
#import "PasswordLoginController1.h"
#import <Masonry/Masonry.h>
#import "AgreementView.h"
#import "AgreementWebViewController.h"

@interface LoginController() <AgreementViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *passwordLoginBtn;
@property (nonatomic, strong) UIView *inputBgView;
@property (nonatomic, strong) UILabel *areaCodeLabel;
@property (nonatomic, strong) UIView *separator;
@property (nonatomic, strong) UITextField *phoneField;
@property (nonatomic, strong) UIButton *getCodeBtn;
@property (nonatomic, strong) AgreementView *agreementView;

@end

@implementation LoginController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = YES;
    [self.view setBackgroundColor:kColor_BG];
    [self setupUI];
    [self rac_notification_register];
    
    // 延迟一小段时间后自动弹出键盘
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.phoneField becomeFirstResponder];
    });
}

- (void)setupUI {
    // 标题
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.text = @"验证码登录";
    _titleLabel.font = [UIFont systemFontOfSize:32];
    [self.view addSubview:_titleLabel];
    
    // 关闭按钮
    _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_closeButton setImage:[UIImage imageNamed:@"login_close"] forState:UIControlStateNormal];
    [_closeButton setImage:[UIImage imageNamed:@"login_close_h"] forState:UIControlStateHighlighted];
    [_closeButton addTarget:self action:@selector(closeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_closeButton];
    
    // 密码登录按钮
    _passwordLoginBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_passwordLoginBtn setTitle:@"密码登录" forState:UIControlStateNormal];
    [_passwordLoginBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    _passwordLoginBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [_passwordLoginBtn addTarget:self action:@selector(passwordLoginClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_passwordLoginBtn];
    
    // 输入框背景
    _inputBgView = [[UIView alloc] init];
    _inputBgView.backgroundColor = [UIColor whiteColor];
    _inputBgView.layer.cornerRadius = 8;
    _inputBgView.layer.borderWidth = 1;
    _inputBgView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [self.view addSubview:_inputBgView];
    
    // 区号标签
    _areaCodeLabel = [[UILabel alloc] init];
    _areaCodeLabel.text = @"+86";
    _areaCodeLabel.font = [UIFont systemFontOfSize:16];
    _areaCodeLabel.textColor = [UIColor systemBlueColor];
    [_inputBgView addSubview:_areaCodeLabel];
    
    // 分割线
    _separator = [[UIView alloc] init];
    _separator.backgroundColor = [UIColor systemGray4Color];
    [_inputBgView addSubview:_separator];
    
    // 手机号输入框
    _phoneField = [[UITextField alloc] init];
    _phoneField.placeholder = @"请输入手机号";
    _phoneField.font = [UIFont systemFontOfSize:14];
    _phoneField.keyboardType = UIKeyboardTypeNumberPad;
    _phoneField.delegate = self;
    [_phoneField addTarget:self action:@selector(textFieldDidEditing:) forControlEvents:UIControlEventEditingChanged];
    [_inputBgView addSubview:_phoneField];
    
    // 获取验证码按钮
    _getCodeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_getCodeBtn setTitle:@"获取验证码" forState:UIControlStateNormal];
    [_getCodeBtn addTarget:self action:@selector(getCodeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_getCodeBtn];
    [self buttonCanTap:NO btn:_getCodeBtn];
    
    // 添加协议视图
    _agreementView = [[AgreementView alloc] initWithShowRegisterTips:YES];
    _agreementView.delegate = self;
    [self.view addSubview:_agreementView];
    
    // 设置约束
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16);
        make.top.equalTo(self.view).offset(90);
    }];
    
    [_closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(10);
        make.left.equalTo(self.view).offset(16);
        make.width.height.equalTo(@40);
    }];
    
    [_passwordLoginBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(26);
        make.right.equalTo(self.view).offset(-20);
        make.height.equalTo(@30);
    }];
    
    [_inputBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.top.equalTo(_titleLabel.mas_bottom).offset(32);
        make.height.equalTo(@55);
    }];
    
    [_areaCodeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_inputBgView).offset(16);
        make.centerY.equalTo(_inputBgView);
        make.width.equalTo(@40);
    }];
    
    [_separator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_areaCodeLabel.mas_right).offset(16);
        make.centerY.equalTo(_inputBgView);
        make.width.equalTo(@1);
        make.height.equalTo(@30);
    }];
    
    [_phoneField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_separator.mas_right).offset(15);
        make.right.equalTo(_inputBgView).offset(-16);
        make.centerY.equalTo(_inputBgView);
    }];
    
    [_getCodeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.top.equalTo(_inputBgView.mas_bottom).offset(16);
        make.height.equalTo(@50);
    }];
    
    [_agreementView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(_getCodeBtn.mas_bottom).offset(16);
        make.height.equalTo(@44);
        make.width.greaterThanOrEqualTo(@200);
    }];
}

// 监听通知
- (void)rac_notification_register {
    @weakify(self)
    // 登录完成
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:USER_LOGIN_COMPLETE object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
        @strongify(self)
        if (self.complete) {
            self.complete();
        }
        [self.navigationController dismissViewControllerAnimated:true completion:nil];
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

// 按钮是否可以点击
- (void)buttonCanTap:(BOOL)tap btn:(UIButton *)btn {
    if (tap == true) {
        [btn setUserInteractionEnabled:YES];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight]];
        [btn setTitleColor:kColor_Text_White forState:UIControlStateNormal];
        [btn setTitleColor:kColor_Text_White forState:UIControlStateHighlighted];
        [btn setBackgroundImage:[UIColor createImageWithColor:kColor_Main_Color] forState:UIControlStateNormal];
        [btn setBackgroundImage:[UIColor createImageWithColor:kColor_Main_Dark_Color] forState:UIControlStateHighlighted];
    } else {
        [btn setUserInteractionEnabled:NO];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight]];
        [btn setTitleColor:kColor_Text_Gary forState:UIControlStateNormal];
        [btn setTitleColor:kColor_Text_Gary forState:UIControlStateHighlighted];
        [btn setBackgroundImage:[UIColor createImageWithColor:kColor_Line_Color] forState:UIControlStateNormal];
        [btn setBackgroundImage:[UIColor createImageWithColor:kColor_Line_Color] forState:UIControlStateHighlighted];
    }
    [btn.layer setCornerRadius:8];
    [btn.layer setMasksToBounds:YES];
}


#pragma mark - http request
- (void)getSmsCodeRequest {
    NSString *phone = [self.phoneField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSDictionary *param = [NSDictionary dictionaryWithObjectsAndKeys:phone, @"phone", nil];
    
    [self showProgressHUD];
    [self.view endEditing:true];
    [AFNManager POST:userSmsCodeRequest params:param complete:^(APPResult *result) {
        [self hideHUD];
        if (result.status == HttpStatusSuccess && result.code == BIZ_SUCCESS) {
            NSDictionary *dic = result.data;
            NSString *code = [dic objectForKey:@"code"];
            [self showTextHUD:[@"" stringByAppendingString:code] delay:2.0f];
            VerifyController *vc = [[VerifyController alloc] init];
            vc.phone = [self.phoneField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
            vc.code = code;
            [self.navigationController pushViewController:vc animated:YES];
        } else {
            [self showTextHUD:result.msg delay:1.5f];
        }
    }];
}

#pragma mark - click
- (IBAction)getCodeBtnClick:(UIButton *)sender {
    [self getSmsCodeRequest];
}

// 关闭
- (IBAction)closeBtnClick:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

// 文本编辑
- (void)textFieldDidEditing:(UITextField *)textField {
    if (textField == self.phoneField) {
        NSString *text = textField.text;
        // 保存当前光标位置
        NSInteger currentLocation = [textField offsetFromPosition:textField.beginningOfDocument toPosition:textField.selectedTextRange.start];
        
        // 去除所有空格
        text = [text stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        if (text.length > 11) {
            text = [text substringToIndex:11];
        }
        
        // 格式化手机号 3 4 4 格式
        NSMutableString *formattedString = [NSMutableString string];
        for (NSInteger i = 0; i < text.length; i++) {
            [formattedString appendString:[text substringWithRange:NSMakeRange(i, 1)]];
            if ((i == 2 || i == 6) && i < text.length - 1) {
                [formattedString appendString:@" "];
            }
        }
        
        // 计算新的光标位置
        NSInteger numSpacesBeforeCursor = 0;
        NSInteger originalTextLength = text.length;
        if (currentLocation > 3) numSpacesBeforeCursor++;
        if (currentLocation > 7) numSpacesBeforeCursor++;
        
        // 更新文本
        textField.text = formattedString;
        
        // 设置新的光标位置
        NSInteger newLocation = MIN(currentLocation + numSpacesBeforeCursor, formattedString.length);
        UITextPosition *newPosition = [textField positionFromPosition:textField.beginningOfDocument offset:newLocation];
        textField.selectedTextRange = [textField textRangeFromPosition:newPosition toPosition:newPosition];
        
        // 根据实际号码长度（去除空格后）和协议选中状态设置按钮是否可点击
        [self buttonCanTap:self.agreementView.isSelected && text.length == 11 btn:self.getCodeBtn];
    }
}

// 添加点击事件处理
- (void)passwordLoginClick {
    PasswordLoginController1 *vc = [[PasswordLoginController1 alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

// 实现代理方法
#pragma mark - AgreementViewDelegate
- (void)agreementViewDidChangeState:(BOOL)isSelected {
    // 根据协议选中状态更新按钮状态
    [self buttonCanTap:isSelected && self.phoneField.text.length == 13 btn:self.getCodeBtn];
}

- (void)agreementViewDidTapUserAgreement {
    AgreementWebViewController *vc = [[AgreementWebViewController alloc] initWithTitle:@"用户协议" url:@"https://book.vance.xin/apps/jiya/legal/terms_of_service.html"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)agreementViewDidTapPrivacyAgreement {
    AgreementWebViewController *vc = [[AgreementWebViewController alloc] initWithTitle:@"隐私政策" url:@"https://book.vance.xin/apps/jiya/legal/privacy_policy.html"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // 打印视图层级，检查是否有遮挡
    [self printViewHierarchy:self.view level:0];
}

- (void)printViewHierarchy:(UIView *)view level:(int)level {
    NSMutableString *indent = [NSMutableString string];
    for (int i = 0; i < level; i++) {
        [indent appendString:@"  "];
    }
    NSLog(@"%@%@ frame:%@ userInteractionEnabled:%d", indent, [view class], NSStringFromCGRect(view.frame), view.userInteractionEnabled);
    for (UIView *subview in view.subviews) {
        [self printViewHierarchy:subview level:level + 1];
    }
}

@end
