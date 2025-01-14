/**
 * 删除账号
 */

#import "DeleteAccountController.h"
#import "AlertViewManager.h"
#import <Masonry/Masonry.h>

@interface DeleteAccountController()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UILabel *conditionLabel1;
@property (nonatomic, strong) UILabel *conditionLabel2;
@property (nonatomic, strong) UILabel *conditionLabel3;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *cancelButton;

@end

@implementation DeleteAccountController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.hbd_barHidden = NO;
    self.hbd_barTintColor = kColor_Main_Color;
    [self setNavTitle:@"删除账号"];
    [self setupUI];
    [self setupConstraints];
}

#pragma mark - 初始化UI
- (void)setupUI {
    // 标题
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.text = @"你正在进行删除账号操作";
    _titleLabel.font = [UIFont systemFontOfSize:AdjustFont(16) weight:UIFontWeightMedium];
    _titleLabel.textColor = kColor_Text_Black;
    [self.view addSubview:_titleLabel];
    
    // 描述
    _descLabel = [[UILabel alloc] init];
    _descLabel.text = @"账号一旦删除，将无法恢复。请务必仔细思考，谨慎操作。";
    _descLabel.font = [UIFont systemFontOfSize:AdjustFont(12)];
    _descLabel.textColor = kColor_Text_Gary;
    _descLabel.numberOfLines = 0;
    [self.view addSubview:_descLabel];
    
    // 条件1
    _conditionLabel1 = [[UILabel alloc] init];
    _conditionLabel1.text = @"- 删除账号后，您的所有数据将被清除，包括账单记录、预算设置等；";
    _conditionLabel1.font = [UIFont systemFontOfSize:AdjustFont(12)];
    _conditionLabel1.textColor = kColor_Text_Gary;
    _conditionLabel1.numberOfLines = 0;
    [self.view addSubview:_conditionLabel1];
    
    // 条件2
    _conditionLabel2 = [[UILabel alloc] init];
    _conditionLabel2.text = @"- 删除账号后，您将无法找回任何历史数据；";
    _conditionLabel2.font = [UIFont systemFontOfSize:AdjustFont(12)];
    _conditionLabel2.textColor = kColor_Text_Gary;
    _conditionLabel2.numberOfLines = 0;
    [self.view addSubview:_conditionLabel2];
    
    // 条件3
    _conditionLabel3 = [[UILabel alloc] init];
    _conditionLabel3.text = @"- 删除账号后，您可以使用相同的手机号重新注册，但之前的数据无法恢复。";
    _conditionLabel3.font = [UIFont systemFontOfSize:AdjustFont(12)];
    _conditionLabel3.textColor = kColor_Text_Gary;
    _conditionLabel3.numberOfLines = 0;
    [self.view addSubview:_conditionLabel3];
    
    // 删除按钮
    _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_deleteButton setTitle:@"申请删除" forState:UIControlStateNormal];
    [_deleteButton setTitleColor:kColor_Text_Black forState:UIControlStateNormal];
    _deleteButton.titleLabel.font = [UIFont systemFontOfSize:AdjustFont(14)];
    _deleteButton.backgroundColor = [UIColor whiteColor];
    _deleteButton.layer.cornerRadius = 8;
    _deleteButton.layer.borderWidth = 1;
    _deleteButton.layer.borderColor = kColor_Line_Color.CGColor;
    [_deleteButton addTarget:self action:@selector(deleteButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_deleteButton];
    
    // 取消按钮
    _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_cancelButton setTitle:@"我再想想" forState:UIControlStateNormal];
    [_cancelButton setTitleColor:kColor_Text_White forState:UIControlStateNormal];
    _cancelButton.titleLabel.font = [UIFont systemFontOfSize:AdjustFont(14)];
    _cancelButton.backgroundColor = kColor_Main_Color;
    _cancelButton.layer.cornerRadius = 8;
    [_cancelButton addTarget:self action:@selector(cancelButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_cancelButton];
}

#pragma mark - 设置约束
- (void)setupConstraints {
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(20);
        make.left.equalTo(self.view).offset(15);
        make.right.equalTo(self.view).offset(-15);
    }];
    
    [_descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_titleLabel.mas_bottom).offset(20);
        make.left.right.equalTo(_titleLabel);
    }];
    
    [_conditionLabel1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_descLabel.mas_bottom).offset(30);
        make.left.right.equalTo(_titleLabel);
    }];
    
    [_conditionLabel2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_conditionLabel1.mas_bottom).offset(20);
        make.left.right.equalTo(_titleLabel);
    }];
    
    [_conditionLabel3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_conditionLabel2.mas_bottom).offset(20);
        make.left.right.equalTo(_titleLabel);
    }];
    
    [_deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(15);
        make.right.equalTo(self.view).offset(-15);
        make.height.equalTo(@45);
        make.bottom.equalTo(_cancelButton.mas_top).offset(-15);
    }];
    
    [_cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.height.equalTo(_deleteButton);
        make.bottom.equalTo(self.view).offset(-40);
    }];
}

#pragma mark - 按钮事件
- (void)deleteButtonClick {
    // 按钮二维数组，array[0] 存放 title 数组, array[1] 存放 style 数组
    NSArray<NSArray *> *buttonArray = @[
        @[@"删除"],
        @[[NSNumber numberWithInteger:UIAlertActionStyleDestructive]]
    ];
    
    [[AlertViewManager sharedInstacne] showSheet:@"记呀" 
                                       message:@"删除后账号将无法恢复，确定要删除吗？" 
                                  cancelTitle:@"取消" 
                               viewController:self 
                                    confirm:^(NSInteger buttonTag, NSString *buttonTitle) {
        if (buttonTag == 0) {
            [self deleteAccountRequest];
        }
    } buttonArray:buttonArray];
}

- (void)cancelButtonClick {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - 网络请求
- (void)deleteAccountRequest {
    [self showProgressHUD];
    @weakify(self)
    [AFNManager POST:DeleteAccountRequest params:nil complete:^(APPResult *result) {
        @strongify(self)
        [self hideHUD];
        if (result.status == HttpStatusSuccess && result.code == BIZ_SUCCESS) {
            [self showTextHUD:@"账号已删除" delay:1.5f];
            [UserInfo clearUserInfo];
            [[NSNotificationCenter defaultCenter] postNotificationName:USER_LOGOUT_COMPLETE object:nil];
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else {
            [self showTextHUD:result.msg delay:1.5f];
        }
    }];
}

@end
