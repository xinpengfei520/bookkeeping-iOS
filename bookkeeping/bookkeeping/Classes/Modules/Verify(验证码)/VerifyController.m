//
//  VerifyController.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/7/10.
//  Copyright © 2022 kk. All rights reserved.
//

#import "VerifyController.h"
#import "LOGIN_NOTIFICATION.h"


@interface VerifyController ()

@property (nonatomic, strong) CountDown *countDown;

@end

@implementation VerifyController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    NSString *phoneDesc = [@"短信验证码已发送至+86*******" stringByAppendingString:[_phone substringFromIndex:7]];
    [self.phoneLab setText:phoneDesc];
    [self.inputBgView borderForColor:[UIColor lightGrayColor] borderWidth:1.f borderType:UIBorderSideTypeAll];
    [self.inputBgView.layer setCornerRadius:8];
    [self.inputBgView.layer setBorderWidth:1];
    [self.inputBgView.layer setMasksToBounds:YES];
    
    [self buttonCanTap:false btn:_verifyBtn];
    
    [self.codeTextField addTarget:self action:@selector(textFieldDidEditing:) forControlEvents:UIControlEventEditingChanged];
    [self countDownBegin];
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

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

// 文本编辑
- (void)textFieldDidEditing:(UITextField *)textField {
    // 根据输入的验证码位数设置登录按钮是否可点击
    if (self.codeTextField.text.length == 6) {
        [self buttonCanTap:true btn:self.verifyBtn];
    } else {
        [self buttonCanTap:false btn:self.verifyBtn];
    }
}

- (IBAction)verifyBtnAction:(id)sender {
    [self verifyRequest];
}

#pragma mark - http request
- (void)verifyRequest {
    NSDictionary *param = [NSDictionary dictionaryWithObjectsAndKeys:self.phone, @"phone",
                           self.codeTextField.text, @"code", nil];
    
    [self showProgressHUD];
    [self.view endEditing:true];
    [AFNManager POST:userLoginRequest params:param complete:^(APPResult *result) {
        [self hideHUD];
        if (result.status == HttpStatusSuccess && result.code == BIZ_SUCCESS) {
            [self showTextHUD:@"登录成功" delay:1.5f];
            [[NSNotificationCenter defaultCenter] postNotificationName:USER_LOGIN_COMPLETE object:nil];
        } else {
            [self showTextHUD:result.msg delay:1.5f];
        }
    }];
}

- (void)countDownBegin {
    [self.countDown countDownWithStratTimeStamp:0 finishTimeStamp:59 * 1000 completeBlock:^(NSInteger day, NSInteger hour, NSInteger minute, NSInteger second) {
        if (second != 0 || minute != 0) {
            NSString *str = [NSString stringWithFormat:@"%02lds 后可重新获取", second];
            [self.countDownLab setText:str];
            [self.countDownLab setTextColor:[UIColor lightGrayColor]];
            [self.countDownLab setUserInteractionEnabled:NO];
        } else {
            [self.countDownLab setText:@"重新获取"];
            [self.countDownLab setTextColor:[UIColor systemBlueColor]];
            [self.countDownLab setUserInteractionEnabled:YES];
        }
    }];
}

#pragma mark - get
- (CountDown *)countDown {
    if (!_countDown) {
        _countDown = [[CountDown alloc] init];
    }
    return _countDown;
}

@end
