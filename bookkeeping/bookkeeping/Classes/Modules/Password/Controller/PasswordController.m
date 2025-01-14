/**
 * 修改密码
 * @author 郑业强 2018-12-24 创建文件
 */

#import "PasswordController.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface PasswordController()

@property (nonatomic, strong) UILabel *nameLab1;
@property (nonatomic, strong) UILabel *nameLab2;
@property (nonatomic, strong) UILabel *nameLab3;
@property (nonatomic, strong) UITextField *field1;
@property (nonatomic, strong) UITextField *field2;
@property (nonatomic, strong) UITextField *field3;
@property (nonatomic, strong) UIButton *completeBtn;
@property (nonatomic, strong) UIView *line1;
@property (nonatomic, strong) UIView *line2;
@property (nonatomic, strong) UIView *line3;

@end

#pragma mark - 实现
@implementation PasswordController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.hbd_barHidden = NO;
    self.hbd_barTintColor = kColor_Main_Color;
    [self setNavTitle:@"修改密码"];
    [self setupUI];
    [self setupConstraints];
    [self setupEvents];
}

#pragma mark - 初始化UI
- (void)setupUI {
    // 旧密码标签
    _nameLab1 = [[UILabel alloc] init];
    _nameLab1.text = @"旧密码";
    _nameLab1.font = [UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight];
    _nameLab1.textColor = kColor_Text_Black;
    [self.view addSubview:_nameLab1];
    
    // 旧密码输入框
    _field1 = [[UITextField alloc] init];
    _field1.placeholder = @"请输入旧密码";
    _field1.font = [UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight];
    _field1.textColor = kColor_Text_Black;
    _field1.secureTextEntry = YES;
    _field1.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.view addSubview:_field1];
    
    // 分隔线1
    _line1 = [[UIView alloc] init];
    _line1.backgroundColor = kColor_Line_Color;
    [self.view addSubview:_line1];
    
    // 新密码标签
    _nameLab2 = [[UILabel alloc] init];
    _nameLab2.text = @"新密码";
    _nameLab2.font = [UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight];
    _nameLab2.textColor = kColor_Text_Black;
    [self.view addSubview:_nameLab2];
    
    // 新密码输入框
    _field2 = [[UITextField alloc] init];
    _field2.placeholder = @"6-18位数字、字母组合";
    _field2.font = [UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight];
    _field2.textColor = kColor_Text_Black;
    _field2.secureTextEntry = YES;
    _field2.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.view addSubview:_field2];
    
    // 分隔线2
    _line2 = [[UIView alloc] init];
    _line2.backgroundColor = kColor_Line_Color;
    [self.view addSubview:_line2];
    
    // 确认密码标签
    _nameLab3 = [[UILabel alloc] init];
    _nameLab3.text = @"确认密码";
    _nameLab3.font = [UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight];
    _nameLab3.textColor = kColor_Text_Black;
    [self.view addSubview:_nameLab3];
    
    // 确认密码输入框
    _field3 = [[UITextField alloc] init];
    _field3.placeholder = @"请再次输入密码";
    _field3.font = [UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight];
    _field3.textColor = kColor_Text_Black;
    _field3.secureTextEntry = YES;
    _field3.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.view addSubview:_field3];
    
    // 分隔线3
    _line3 = [[UIView alloc] init];
    _line3.backgroundColor = kColor_Line_Color;
    [self.view addSubview:_line3];
    
    // 确认按钮
    _completeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_completeBtn setTitle:@"确认修改" forState:UIControlStateNormal];
    _completeBtn.layer.cornerRadius = 3;
    _completeBtn.layer.masksToBounds = YES;
    [self.view addSubview:_completeBtn];
    
    [self buttonCanTap:NO];
}

#pragma mark - 设置约束
- (void)setupConstraints {
    // 旧密码标签
    [_nameLab1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(15);
        make.top.equalTo(self.view).offset(20);
        make.height.equalTo(@50);
        make.width.equalTo(@90);
    }];
    
    // 旧密码输入框
    [_field1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_nameLab1.mas_right).offset(5);
        make.right.equalTo(self.view).offset(-15);
        make.centerY.height.equalTo(_nameLab1);
    }];
    
    // 分隔线1
    [_line1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_nameLab1);
        make.right.equalTo(_field1);
        make.top.equalTo(_nameLab1.mas_bottom);
        make.height.equalTo(@1);
    }];
    
    // 新密码标签
    [_nameLab2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.width.equalTo(_nameLab1);
        make.top.equalTo(_line1.mas_bottom).offset(15);
        make.height.equalTo(_nameLab1);
    }];
    
    // 新密码输入框
    [_field2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_nameLab2.mas_right).offset(5);
        make.right.equalTo(_field1);
        make.centerY.height.equalTo(_nameLab2);
    }];
    
    // 分隔线2
    [_line2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.height.equalTo(_line1);
        make.top.equalTo(_nameLab2.mas_bottom);
    }];
    
    // 确认密码标签
    [_nameLab3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.width.equalTo(_nameLab1);
        make.top.equalTo(_line2.mas_bottom).offset(15);
        make.height.equalTo(_nameLab1);
    }];
    
    // 确认密码输入框
    [_field3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_nameLab3.mas_right).offset(5);
        make.right.equalTo(_field1);
        make.centerY.height.equalTo(_nameLab3);
    }];
    
    // 分隔线3
    [_line3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.height.equalTo(_line1);
        make.top.equalTo(_nameLab3.mas_bottom);
    }];
    
    // 确认按钮
    [_completeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_nameLab1);
        make.right.equalTo(_field1);
        make.top.equalTo(_line3.mas_bottom).offset(50);
        make.height.equalTo(@45);
    }];
}

#pragma mark - 设置事件
- (void)setupEvents {
    [_field1 addTarget:self action:@selector(fieldValueChange:) forControlEvents:UIControlEventEditingChanged];
    [_field2 addTarget:self action:@selector(fieldValueChange:) forControlEvents:UIControlEventEditingChanged];
    [_field3 addTarget:self action:@selector(fieldValueChange:) forControlEvents:UIControlEventEditingChanged];
    [_completeBtn addTarget:self action:@selector(completeClick:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - 请求
- (void)getChangeRequest {
    NSString *pass1 =self.field2.text;
    NSString *pass2 =self.field3.text;
    
    if (![pass1 isEqualToString:pass2]) {
        [self showTextHUD:@"两次密码不一致" delay:1.f];
        return;
    }
    
    if (pass1.length < 6 || pass1.length > 18) {
        [self showTextHUD:@"密码长度为6-18位" delay:1.f];
        return;
    }
    
    UserModel *model = [UserInfo loadUserInfo];
    NSLog(@"%@, %@, %@", model.userName, self.field1.text, self.field3.text);
    NSDictionary *param = @{@"phone": model.userName,
                            @"oldPassword": self.field1.text,
                            @"password": self.field3.text};
    [self showProgressHUD];
    [self.view endEditing:true];
    @weakify(self)
    [AFNManager POST:ChangePassRequest params:param complete:^(APPResult *result) {
        @strongify(self)
        [self hideHUD];
        if (result.status == HttpStatusSuccess) {
            // 修改成功
            if (result.code ==0) {
                [self showWindowTextHUD:@"修改成功" delay:1.f];
                [self.navigationController popViewControllerAnimated:true];
            }else {
                [self showTextHUD:result.msg delay:1.f];
            }
        } else {
            [self showTextHUD:result.msg delay:1.f];
        }
    }];
}

// 完成
- (IBAction)completeClick:(UIButton *)sender {
    [self getChangeRequest];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:true];
}

// 按钮是否可以点击
- (void)buttonCanTap:(BOOL)tap {
    if (tap == true) {
        [self.completeBtn setUserInteractionEnabled:YES];
        [self.completeBtn.titleLabel setFont:[UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight]];
        [self.completeBtn setTitleColor:kColor_Text_Black forState:UIControlStateNormal];
        [self.completeBtn setTitleColor:kColor_Text_Black forState:UIControlStateHighlighted];
        [self.completeBtn setBackgroundImage:[UIColor createImageWithColor:kColor_Main_Color] forState:UIControlStateNormal];
        [self.completeBtn setBackgroundImage:[UIColor createImageWithColor:kColor_Main_Dark_Color] forState:UIControlStateHighlighted];
    } else {
        [self.completeBtn setUserInteractionEnabled:NO];
        [self.completeBtn.titleLabel setFont:[UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight]];
        [self.completeBtn setTitleColor:kColor_Text_Gary forState:UIControlStateNormal];
        [self.completeBtn setTitleColor:kColor_Text_Gary forState:UIControlStateHighlighted];
        [self.completeBtn setBackgroundImage:[UIColor createImageWithColor:kColor_Line_Color] forState:UIControlStateNormal];
        [self.completeBtn setBackgroundImage:[UIColor createImageWithColor:kColor_Line_Color] forState:UIControlStateHighlighted];
    }
}

- (void)fieldValueChange:(UITextField *)textField {
    if (self.field1.text.length != 0 && self.field2.text.length != 0 && self.field3.text.length != 0) {
        if ([self.field2.text isEqualToString:self.field3.text]) {
            [self buttonCanTap:true];
        } else {
            [self buttonCanTap:false];
        }
    } else {
        [self buttonCanTap:false];
    }
}



@end
