#import "PasswordLoginController1.h"
#import "PasswordLoginController2.h"
#import <Masonry/Masonry.h>
#import "AgreementView.h"

@interface PasswordLoginController1() <AgreementViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UITextField *phoneField;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIView *inputBgView;
@property (nonatomic, strong) UILabel *areaCodeLabel;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) AgreementView *agreementView;

@end

@implementation PasswordLoginController1

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = YES;
    [self.view setBackgroundColor:kColor_BG];
    [self setupUI];
    
    // 延迟一小段时间后自动弹出键盘，确保视图已经完全加载
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.phoneField becomeFirstResponder];
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
    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = [UIColor systemGray4Color];
    [_inputBgView addSubview:separator];
    
    // 手机号输入框
    _phoneField = [[UITextField alloc] init];
    _phoneField.placeholder = @"请输入手机号";
    _phoneField.font = [UIFont systemFontOfSize:14];
    _phoneField.keyboardType = UIKeyboardTypeNumberPad;
    _phoneField.delegate = self;
    [_phoneField addTarget:self action:@selector(textFieldDidEditing:) forControlEvents:UIControlEventEditingChanged];
    [_inputBgView addSubview:_phoneField];
    
    // 下一步按钮
    _nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_nextButton setTitle:@"下一步" forState:UIControlStateNormal];
    [_nextButton addTarget:self action:@selector(nextButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_nextButton];
    [self buttonCanTap:NO btn:_nextButton];
    
    // 添加协议视图
    _agreementView = [[AgreementView alloc] initWithShowRegisterTips:NO];
    _agreementView.delegate = self;
    [self.view addSubview:_agreementView];
    
    [_agreementView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(_nextButton.mas_bottom).offset(16);
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
    
    [_inputBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.top.equalTo(titleLabel.mas_bottom).offset(32);
        make.height.equalTo(@55);
    }];
    
    [_areaCodeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_inputBgView).offset(16);
        make.centerY.equalTo(_inputBgView);
        make.width.equalTo(@40);
    }];
    
    [separator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_areaCodeLabel.mas_right).offset(16);
        make.centerY.equalTo(_inputBgView);
        make.width.equalTo(@1);
        make.height.equalTo(@30);
    }];
    
    [_phoneField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(separator.mas_right).offset(15);
        make.right.equalTo(_inputBgView).offset(-16);
        make.centerY.equalTo(_inputBgView);
    }];
    
    [_nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.top.equalTo(_inputBgView.mas_bottom).offset(16);
        make.height.equalTo(@50);
    }];
}

#pragma mark - Actions
- (void)closeBtnClick {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)nextButtonClick {
    NSString *phone = [self.phoneField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    PasswordLoginController2 *vc = [[PasswordLoginController2 alloc] init];
    vc.phone = phone;
    vc.complete = self.complete;
    [self.navigationController pushViewController:vc animated:YES];
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
    if (textField == self.phoneField) {
        NSString *text = textField.text;
        text = [text stringByReplacingOccurrencesOfString:@" " withString:@""]; // 先去除所有空格
        
        if (text.length > 11) {
            text = [text substringToIndex:11]; // 限制最大长度为11位
        }
        
        // 格式化手机号 3 4 4 格式
        NSMutableString *formattedString = [NSMutableString string];
        for (NSInteger i = 0; i < text.length; i++) {
            [formattedString appendString:[text substringWithRange:NSMakeRange(i, 1)]];
            if (i == 2 || i == 6) {
                [formattedString appendString:@" "];
            }
        }
        
        // 更新文本，但不触发递归
        if (![textField.text isEqualToString:formattedString]) {
            textField.text = formattedString;
        }
        
        // 根据实际号码长度（去除空格后）和协议选中状态设置按钮是否可点击
        NSString *pureNumber = [formattedString stringByReplacingOccurrencesOfString:@" " withString:@""];
        [self buttonCanTap:self.agreementView.isSelected && pureNumber.length == 11 btn:self.nextButton];
    }
}

#pragma mark - AgreementViewDelegate
- (void)agreementViewDidChangeState:(BOOL)isSelected {
    [self buttonCanTap:isSelected && self.phoneField.text.length == 13 btn:self.nextButton];
}

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

@end 
