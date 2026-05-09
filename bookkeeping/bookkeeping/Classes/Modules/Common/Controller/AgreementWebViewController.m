#import "AgreementWebViewController.h"
#import <WebKit/WebKit.h>
#import <Masonry/Masonry.h>

@interface AgreementWebViewController ()

@property (nonatomic, strong) WKWebView *webView;

@end

@implementation AgreementWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self loadContent];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 设置标题
    self.title = self.type == AgreementTypeUserAgreement ? @"用户协议" : @"隐私政策";
    
    // 创建 WebView
    _webView = [[WKWebView alloc] init];
    [self.view addSubview:_webView];
    
    // 设置约束
    [_webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)loadContent {
    NSString *urlString;
    switch (self.type) {
        case AgreementTypeUserAgreement:
            urlString = kTermsOfServiceURL;
            break;
        case AgreementTypePrivacyPolicy:
            urlString = kPrivacyPolicyURL;
            break;
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [_webView loadRequest:request];
}

@end 