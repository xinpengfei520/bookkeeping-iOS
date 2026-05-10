/**
 * 关于
 * @author 郑业强 2018-12-20 创建文件
 */

#import "AboutController.h"
#import "AgreementWebViewController.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface AboutController()

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *versionLabel;
@property (nonatomic, strong) UIButton *userAgreementBtn;
@property (nonatomic, strong) UIButton *privacyPolicyBtn;
@property (nonatomic, strong) UILabel *icpLabel;

@end

#pragma mark - 实现
@implementation AboutController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = KKLocalized(@"关于");
    [self setupUI];
    [self setupConstraints];
}

#pragma mark - 初始化UI
- (void)setupUI {
    // App图标
    _iconView = [[UIImageView alloc] init];
    _iconView.image = [UIImage imageNamed:@"AppPreview"];
    _iconView.contentMode = UIViewContentModeScaleAspectFit;
    _iconView.layer.cornerRadius = 16;
    _iconView.clipsToBounds = YES;
    [self.view addSubview:_iconView];
    
    // App名称（动态获取）
    _titleLabel = [[UILabel alloc] init];
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    _titleLabel.text = [infoDictionary objectForKey:@"CFBundleDisplayName"] ?: KKLocalized(@"记呀");
    _titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightMedium];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_titleLabel];
    
    // 版本号
    _versionLabel = [[UILabel alloc] init];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    _versionLabel.text = [NSString stringWithFormat:@"V%@(%@)", version, build];
    _versionLabel.font = [UIFont systemFontOfSize:AdjustFont(14)];
    _versionLabel.textColor = kColor_Text_Gary;
    _versionLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_versionLabel];
    
    // 用户协议 / 隐私政策按钮：用蓝色 + 下划线 attributedTitle 模拟超链接
    // 视觉，让用户一眼看到"可点击"。systemBlueColor 是 dynamic color，深色
    // 模式下自动切到夜间蓝（约 RGB 10/132/255），不需要手动 colorScheme 分支。
    NSDictionary *linkAttrs = @{
        NSForegroundColorAttributeName: [UIColor systemBlueColor],
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
        NSFontAttributeName: [UIFont systemFontOfSize:AdjustFont(14)],
    };

    _userAgreementBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_userAgreementBtn setAttributedTitle:[[NSAttributedString alloc] initWithString:KKLocalized(@"用户协议") attributes:linkAttrs]
                                 forState:UIControlStateNormal];
    [_userAgreementBtn addTarget:self action:@selector(userAgreementClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_userAgreementBtn];

    _privacyPolicyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_privacyPolicyBtn setAttributedTitle:[[NSAttributedString alloc] initWithString:KKLocalized(@"隐私政策") attributes:linkAttrs]
                                 forState:UIControlStateNormal];
    [_privacyPolicyBtn addTarget:self action:@selector(privacyPolicyClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_privacyPolicyBtn];
    
    // 备案号
    _icpLabel = [[UILabel alloc] init];
    _icpLabel.text = KKLocalized(@"沪ICP备2022014461号-3A");
    _icpLabel.font = [UIFont systemFontOfSize:AdjustFont(12)];
    _icpLabel.textColor = kColor_Text_Gary;
    _icpLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_icpLabel];
}

#pragma mark - 设置约束
- (void)setupConstraints {
    // Logo
    [_iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view).offset(NavigationBarHeight + 20);
        make.width.height.equalTo(@100);
    }];

    // App名称
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(_iconView.mas_bottom).offset(10);
    }];
    
    // 版本号
    [_versionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(_titleLabel.mas_bottom).offset(10);
    }];
    
    // 用户协议按钮
    [_userAgreementBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view).offset(-50);
        make.top.equalTo(_versionLabel.mas_bottom).offset(30);
        make.height.equalTo(@44);
    }];
    
    // 隐私政策按钮
    [_privacyPolicyBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view).offset(50);
        make.centerY.equalTo(_userAgreementBtn);
        make.height.equalTo(@44);
    }];
    
    // 备案号
    [_icpLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-40);
    }];
}

#pragma mark - 事件处理
- (void)userAgreementClick {
    AgreementWebViewController *vc = [[AgreementWebViewController alloc] init];
    vc.type = AgreementTypeUserAgreement;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)privacyPolicyClick {
    AgreementWebViewController *vc = [[AgreementWebViewController alloc] init];
    vc.type = AgreementTypePrivacyPolicy;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
