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
@property (nonatomic, strong) UIView *linksContainer;
@property (nonatomic, strong) UILabel *authorLabel;
@property (nonatomic, strong) UIView *githubView;
@property (nonatomic, strong) UIView *twitterView;

@end

#pragma mark - 实现
@implementation AboutController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
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
    
    // App名称
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.text = @"记呀";
    _titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightMedium];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_titleLabel];
    
    // 版本号
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    _versionLabel = [[UILabel alloc] init];
    _versionLabel.text = [NSString stringWithFormat:@"Version %@", appVersion];
    _versionLabel.font = [UIFont systemFontOfSize:16];
    _versionLabel.textColor = [UIColor lightGrayColor];
    _versionLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_versionLabel];
    
    // 作者主页标题
    _authorLabel = [[UILabel alloc] init];
    _authorLabel.text = @"作者主页";
    _authorLabel.font = [UIFont systemFontOfSize:14];
    _authorLabel.textColor = [UIColor lightGrayColor];
    [self.view addSubview:_authorLabel];
    
    // 链接容器
    _linksContainer = [[UIView alloc] init];
    [self.view addSubview:_linksContainer];
    
    // GitHub链接
    _githubView = [self createLinkViewWithTitle:@"GitHub"];
    [_linksContainer addSubview:_githubView];
    
    // 添加点击手势
    UITapGestureRecognizer *githubTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(githubTapped)];
    [_githubView addGestureRecognizer:githubTap];
    
    // Twitter链接
    _twitterView = [self createLinkViewWithTitle:@"Twitter"];
    [_linksContainer addSubview:_twitterView];
    
    // 添加点击手势
    UITapGestureRecognizer *twitterTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(twitterTapped)];
    [_twitterView addGestureRecognizer:twitterTap];
    
    // 确保链接容器可以响应事件
    _linksContainer.userInteractionEnabled = YES;
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
    
    // 作者主页标题约束
    [_authorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16);
        make.top.equalTo(_versionLabel.mas_bottom).offset(40);
    }];
    
    // 链接容器约束
    [_linksContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(_authorLabel.mas_bottom);
    }];
    
    // GitHub链接约束
    [_githubView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(_linksContainer);
        make.top.equalTo(_linksContainer.mas_top);
        make.height.equalTo(@44);
    }];
    
    // Twitter链接约束
    [_twitterView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(_linksContainer);
        make.top.equalTo(_githubView.mas_bottom);
        make.height.equalTo(@44);
    }];
}

#pragma mark - Helper
- (UIView *)createLinkViewWithTitle:(NSString *)title {
    UIView *container = [[UIView alloc] init];
    container.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.1];
    container.userInteractionEnabled = YES; // 确保可以响应事件
    
    // 左侧图标
    UIImageView *linkIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_super_link"]];
    linkIcon.contentMode = UIViewContentModeScaleAspectFit;
    [container addSubview:linkIcon];
    
    // 标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = [UIFont systemFontOfSize:16];
    titleLabel.textColor = [UIColor blackColor];
    [container addSubview:titleLabel];
    
    // 右箭头
    UIImageView *arrowIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_arrow_right"]];
    arrowIcon.contentMode = UIViewContentModeScaleAspectFit;
    [container addSubview:arrowIcon];
    
    // 分割线
    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    [container addSubview:separator];
    
    // 设置约束
    [linkIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(container).offset(16);
        make.centerY.equalTo(container);
        make.width.height.equalTo(@18);
    }];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(linkIcon.mas_right).offset(10);
        make.centerY.equalTo(container);
    }];
    
    [arrowIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(container).offset(-16);
        make.centerY.equalTo(container);
        make.width.height.equalTo(@18);
    }];
    
    [separator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(container).offset(16);
        make.right.equalTo(container);
        make.bottom.equalTo(container);
        make.height.equalTo(@0.5);
    }];
    
    return container;
}

#pragma mark - Button Effects
- (void)buttonTouchDown:(UIButton *)button {
    // 添加点击效果
    button.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
}

- (void)buttonTouchUp:(UIButton *)button {
    // 恢复正常状态
    button.backgroundColor = [UIColor whiteColor];
}

#pragma mark - Actions
- (void)githubTapped {
    NSLog(@"GitHub tapped");
    [self animateViewTap:_githubView];
    NSURL *url = [NSURL URLWithString:@"https://github.com/xinpengfei520"];
    [self openURL:url];
}

- (void)twitterTapped {
    NSLog(@"Twitter tapped");
    [self animateViewTap:_twitterView];
    NSURL *url = [NSURL URLWithString:@"https://twitter.com/vancexin"];
    [self openURL:url];
}

#pragma mark - Helper
- (void)openURL:(NSURL *)url {
    if (!url) {
        NSLog(@"URL is nil");
        return;
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                NSLog(@"Open URL result: %d, URL: %@", success, url);
                if (!success) {
                    NSLog(@"Failed to open url: %@", url);
                }
            }];
        } else {
            [[UIApplication sharedApplication] openURL:url];
        }
    } else {
        NSLog(@"Cannot open URL: %@", url);
    }
}

#pragma mark - Helper
- (void)animateViewTap:(UIView *)view {
    [UIView animateWithDuration:0.1 animations:^{
        view.alpha = 0.5;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            view.alpha = 1.0;
        }];
    }];
}

@end
