/**
 * 手机登录
 * @author 郑业强 2018-12-23 创建文件
 */

#import "LoginController.h"
#import "PasswordLoginController1.h"
#import <Masonry/Masonry.h>
#import "AgreementView.h"
#import "AgreementWebViewController.h"

#pragma mark - 声明
@interface LoginController() <AgreementViewDelegate> {
    NSInteger index;
}

@property (weak, nonatomic) IBOutlet UILabel *areaCodeLab;
@property (weak, nonatomic) IBOutlet UITextField *phoneField;
@property (weak, nonatomic) IBOutlet UIButton *getCodeBtn;
@property (weak, nonatomic) IBOutlet UIView *inputBgView;
@property (nonatomic, strong) AgreementView *agreementView;

@end

#pragma mark - 实现
@implementation LoginController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = YES;
    [self.view setBackgroundColor:kColor_BG];
    
    [self.inputBgView borderForColor:[UIColor lightGrayColor] borderWidth:1.f borderType:UIBorderSideTypeAll];
    [self.inputBgView.layer setCornerRadius:8];
    [self.inputBgView.layer setBorderWidth:1];
    [self.inputBgView.layer setMasksToBounds:YES];
    
    [self.areaCodeLab setFont:[UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight]];
    [self.areaCodeLab setTextColor:[UIColor systemBlueColor]];
    [self.phoneField setFont:[UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight]];
    [self.phoneField setTextColor:kColor_Text_Black];
    
    [self buttonCanTap:false btn:self.getCodeBtn];
    [self.phoneField addTarget:self action:@selector(textFieldDidEditing:) forControlEvents:UIControlEventEditingChanged];
    
    [self rac_notification_register];
    
    // 添加密码登录按钮
    UIButton *passwordLoginBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [passwordLoginBtn setTitle:@"密码登录" forState:UIControlStateNormal];
    [passwordLoginBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    passwordLoginBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [passwordLoginBtn addTarget:self action:@selector(passwordLoginClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:passwordLoginBtn];
    
    // 设置约束
    [passwordLoginBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(26);
        make.right.equalTo(self.view).offset(-20);
        make.height.equalTo(@30);
    }];
    
    // 添加协议视图 - 验证码登录需要显示注册提示
    _agreementView = [[AgreementView alloc] initWithShowRegisterTips:YES];
    _agreementView.delegate = self;
    [self.view addSubview:_agreementView];
    
    [_agreementView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.getCodeBtn.mas_bottom).offset(16);
        make.height.equalTo(@20);
        // 添加宽度约束，确保视图有足够的点击区域
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
    NSString *phone = [self.phoneField.text stringByReplacingOccurrencesOfString:@"-" withString:@""];
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
            vc.phone = [self.phoneField.text stringByReplacingOccurrencesOfString:@"-" withString:@""];
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
