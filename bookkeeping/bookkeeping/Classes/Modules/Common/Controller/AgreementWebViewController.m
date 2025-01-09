#import "AgreementWebViewController.h"
#import <WebKit/WebKit.h>
#import <Masonry/Masonry.h>

@interface AgreementWebViewController () <WKNavigationDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong, readwrite) UIButton *leftButton;

@end

@implementation AgreementWebViewController

- (instancetype)initWithTitle:(NSString *)title url:(NSString *)url {
    self = [super init];
    if (self) {
        self.navTitle = title;
        self.urlString = url;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 设置导航栏
    [self setupNavigationBar];
    
    // 设置 WebView
    [self setupWebView];
    
    // 加载 URL
    [self loadURL];
}

- (void)setupNavigationBar {
    self.title = self.navTitle;
    self.navigationController.navigationBar.hidden = NO;
    
    // 创建返回按钮
    _leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_leftButton setImage:[UIImage imageNamed:@"nav_back_n"] forState:UIControlStateNormal];
    [_leftButton addTarget:self action:@selector(backBtnClick) forControlEvents:UIControlEventTouchUpInside];
    _leftButton.frame = CGRectMake(0, 0, 44, 44);
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_leftButton];
}

- (void)backBtnClick {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setupWebView {
    // 配置 WebView
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.allowsInlineMediaPlayback = YES;
    
    // 创建 WebView
    _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    _webView.navigationDelegate = self;
    _webView.backgroundColor = [UIColor whiteColor];
    _webView.scrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:_webView];
    
    // 添加进度条
    _progressView = [[UIProgressView alloc] init];
    _progressView.progressTintColor = kColor_Main_Color;
    _progressView.trackTintColor = [UIColor clearColor];
    [self.view addSubview:_progressView];
    
    // 监听进度
    [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    
    // 设置约束
    [_webView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        } else {
            make.top.equalTo(self.mas_topLayoutGuideBottom);
            make.bottom.equalTo(self.mas_bottomLayoutGuideTop);
        }
        make.left.right.equalTo(self.view);
    }];
    
    [_progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_webView);
        make.left.right.equalTo(self.view);
        make.height.equalTo(@2);
    }];
}

- (void)loadURL {
    NSURL *url = [NSURL URLWithString:self.urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [_webView loadRequest:request];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        _progressView.progress = _webView.estimatedProgress;
        if (_progressView.progress == 1.0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.progressView.hidden = YES;
            });
        }
    }
}

- (void)dealloc {
    [_webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

@end 