//
//  VerifyController.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/7/10.
//  Copyright © 2022 kk. All rights reserved.
//

#import "VerifyController.h"
#import <Masonry/Masonry.h>

@interface VerifyController() <UITextFieldDelegate>

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UILabel *phoneLabel;
@property (nonatomic, strong) UIView *inputBgView;
@property (nonatomic, strong) UITextField *codeField;
@property (nonatomic, strong) UIButton *verifyButton;
@property (nonatomic, strong) UIButton *resendButton;
@property (nonatomic, assign) NSInteger countdown;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation VerifyController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = YES;
    [self.view setBackgroundColor:kColor_BG];
    [self setupUI];
    
    // 延迟一小段时间后自动弹出键盘
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.codeField becomeFirstResponder];
    });
    
    // 开始倒计时
    [self startCountdown];
}

- (void)setupUI {
    // 标题
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.text = @"验证码";
    _titleLabel.font = [UIFont systemFontOfSize:32];
    [self.view addSubview:_titleLabel];
    
    // 关闭按钮
    _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_closeButton setImage:[UIImage imageNamed:@"login_close"] forState:UIControlStateNormal];
    [_closeButton setImage:[UIImage imageNamed:@"login_close_h"] forState:UIControlStateHighlighted];
    [_closeButton addTarget:self action:@selector(closeBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_closeButton];
    
    // 手机号显示
    _phoneLabel = [[UILabel alloc] init];
    NSMutableString *formattedPhone = [NSMutableString stringWithString:self.phone];
    if (formattedPhone.length == 11) {
        [formattedPhone insertString:@" " atIndex:7];
        [formattedPhone insertString:@" " atIndex:3];
    }
    _phoneLabel.text = [NSString stringWithFormat:@"+86 %@", formattedPhone];
    _phoneLabel.font = [UIFont systemFontOfSize:14];
    _phoneLabel.textColor = [UIColor lightGrayColor];
    [self.view addSubview:_phoneLabel];
    
    // 输入框背景
    _inputBgView = [[UIView alloc] init];
    _inputBgView.backgroundColor = [UIColor whiteColor];
    _inputBgView.layer.cornerRadius = 8;
    _inputBgView.layer.borderWidth = 1;
    _inputBgView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [self.view addSubview:_inputBgView];
    
    // 验证码输入框
    _codeField = [[UITextField alloc] init];
    _codeField.placeholder = @"请输入验证码";
    _codeField.font = [UIFont systemFontOfSize:14];
    _codeField.keyboardType = UIKeyboardTypeNumberPad;
    _codeField.delegate = self;
    [_codeField addTarget:self action:@selector(textFieldDidEditing:) forControlEvents:UIControlEventEditingChanged];
    [_inputBgView addSubview:_codeField];
    
    // 验证按钮
    _verifyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_verifyButton setTitle:@"验证" forState:UIControlStateNormal];
    [_verifyButton addTarget:self action:@selector(verifyBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_verifyButton];
    [self buttonCanTap:NO btn:_verifyButton];
    
    // 重新发送按钮
    _resendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_resendButton setTitle:@"重新发送" forState:UIControlStateNormal];
    [_resendButton setTitleColor:kColor_Main_Color forState:UIControlStateNormal];
    _resendButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [_resendButton addTarget:self action:@selector(resendBtnClick) forControlEvents:UIControlEventTouchUpInside];
    _resendButton.enabled = NO;
    [self.view addSubview:_resendButton];
    
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
    
    [_phoneLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16);
        make.top.equalTo(_titleLabel.mas_bottom).offset(32);
    }];
    
    [_inputBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.top.equalTo(_phoneLabel.mas_bottom).offset(16);
        make.height.equalTo(@55);
    }];
    
    [_codeField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_inputBgView).offset(16);
        make.right.equalTo(_inputBgView).offset(-16);
        make.centerY.equalTo(_inputBgView);
    }];
    
    [_verifyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.top.equalTo(_inputBgView.mas_bottom).offset(16);
        make.height.equalTo(@50);
    }];
    
    [_resendButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(_verifyButton.mas_bottom).offset(16);
        make.height.equalTo(@44);
    }];
}

#pragma mark - Actions
- (void)closeBtnClick {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)verifyBtnClick {
    // 验证码验证逻辑
    [self showProgressHUD];
    NSDictionary *params = @{
        @"phone": [self.phone stringByReplacingOccurrencesOfString:@" " withString:@""],
        @"code": self.codeField.text
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

- (void)resendBtnClick {
    [self startCountdown];
    // 重新发送验证码逻辑
    [self showProgressHUD];
    NSDictionary *params = @{
        @"phone": [self.phone stringByReplacingOccurrencesOfString:@" " withString:@""]
    };
    
    [AFNManager POST:userSmsCodeRequest params:params complete:^(APPResult *result) {
        [self hideHUD];
        if (result.status == HttpStatusSuccess && result.code == BIZ_SUCCESS) {
            [self showTextHUD:@"验证码已发送" delay:1.5f];
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
    // 根据验证码长度设置按钮是否可点击
    [self buttonCanTap:textField.text.length == 6 btn:self.verifyButton];
}

#pragma mark - Countdown
- (void)startCountdown {
    _countdown = 60;
    _resendButton.enabled = NO;
    
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateCountdown) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)updateCountdown {
    _countdown--;
    if (_countdown > 0) {
        [_resendButton setTitle:[NSString stringWithFormat:@"%lds后重新发送", (long)_countdown] forState:UIControlStateNormal];
    } else {
        [_timer invalidate];
        _timer = nil;
        _resendButton.enabled = YES;
        [_resendButton setTitle:@"重新发送" forState:UIControlStateNormal];
    }
}

- (void)dealloc {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

@end
