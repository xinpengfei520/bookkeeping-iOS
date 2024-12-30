/**
 * 关于
 * @author 郑业强 2018-12-20 创建文件
 */

#import "AboutController.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface AboutController()

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *versionLabel;

@end

#pragma mark - 实现
@implementation AboutController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = NO;
    self.hbd_barTintColor = kColor_Main_Color;
    [self setNavTitle:@"关于"];
    [self setupUI];
    [self setupConstraints];
}

#pragma mark - Setup
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
    _titleLabel.text = [infoDictionary objectForKey:@"CFBundleDisplayName"] ?: @"记账";
    _titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightMedium];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_titleLabel];
    
    // 版本号
    NSString *appVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    _versionLabel = [[UILabel alloc] init];
    _versionLabel.text = [NSString stringWithFormat:@"Version %@", appVersion];
    _versionLabel.font = [UIFont systemFontOfSize:16];
    _versionLabel.textColor = [UIColor lightGrayColor];
    _versionLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_versionLabel];
}

- (void)setupConstraints {
    // App图标约束
    [_iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view).offset(120);
        make.width.height.equalTo(@80);
    }];
    
    // App名称约束
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(_iconView.mas_bottom).offset(16);
    }];
    
    // 版本号约束
    [_versionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(_titleLabel.mas_bottom).offset(8);
    }];
}

@end
