/**
 * 手机登录
 * @author 郑业强 2018-12-23 创建文件
 */

#import "LoginController.h"
#import "LOGIN_NOTIFICATION.h"
#import "UIViewController+HBD.h"

#pragma mark - 声明
@interface LoginController() {
    NSInteger index;
}

@property (weak, nonatomic) IBOutlet UILabel *nameLab1;
@property (weak, nonatomic) IBOutlet UITextField *phoneField;
@property (weak, nonatomic) IBOutlet UIButton *getCodeBtn;
@property (weak, nonatomic) IBOutlet UIView *inputBgView;

@end

#pragma mark - 实现
@implementation LoginController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = YES;
    [self.view setBackgroundColor:kColor_BG];
    
    [self.inputBgView borderForColor:[UIColor grayColor] borderWidth:1.f borderType:UIBorderSideTypeAll];
    [self.inputBgView.layer setCornerRadius:8];
    [self.inputBgView.layer setBorderWidth:1];
    [self.inputBgView.layer setMasksToBounds:YES];
    
    [self.nameLab1 setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.nameLab1 setTextColor:kColor_Text_Black];
    [self.phoneField setFont:[UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight]];
    [self.phoneField setTextColor:kColor_Text_Black];
    
    [self buttonCanTap:false btn:self.getCodeBtn];
    [self.phoneField addTarget:self action:@selector(textFieldDidEditing:) forControlEvents:UIControlEventEditingChanged];
    
    [self rac_notification_register];
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
            [self showTextHUD:[@"发送成功，验证码为：" stringByAppendingString:code] delay:6.5f];
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
        if (textField.text.length > index) {
            // 输入
            if (textField.text.length == 4 || textField.text.length == 9 ) {
                NSMutableString * str = [[NSMutableString alloc ] initWithString:textField.text];
                [str insertString:@"-" atIndex:(textField.text.length-1)];
                textField.text = str;
            }
            // 输入完成
            if (textField.text.length >= 13) {
                textField.text = [textField.text substringToIndex:13];
            }
            index = textField.text.length;
        }
        // 删除
        else if (textField.text.length < index) {
            if (textField.text.length == 4 || textField.text.length == 9) {
                textField.text = [NSString stringWithFormat:@"%@",textField.text];
                textField.text = [textField.text substringToIndex:(textField.text.length-1)];
            }
            index = textField.text.length;
        }
    }
    
    // 根据输入的手机号位数设置发送验证码按钮是否可点击
    if (self.phoneField.text.length == 13) {
        [self buttonCanTap:true btn:self.getCodeBtn];
    } else {
        [self buttonCanTap:false btn:self.getCodeBtn];
    }
}

@end
