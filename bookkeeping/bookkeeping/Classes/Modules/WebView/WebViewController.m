//
//  WebViewController.m
//  ZhongLv
//
//  Created by zhongke on 2018/11/14.
//  Copyright © 2018年 iOSlmm. All rights reserved.
//

#import "WebViewController.h"
#import <WebKit/WebKit.h>

#pragma mark - 声明
@interface WebViewController()<WKUIDelegate, WKNavigationDelegate>

@property (nonatomic, strong) WKWebView *web;
@property (nonatomic, strong) UIProgressView *myProgressView;
// 添加标记，用于记录是否有导航历史
@property (nonatomic, assign) BOOL hasNavigationHistory;

@end

#pragma mark - 实现
@implementation WebViewController


- (instancetype)init {
    if (self = [super init]) {
        _showProgress = YES;
        _hasNavigationHistory = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = NO;
    self.hbd_barTintColor = kColor_Main_Color;
    [self setNavTitle:@"帮助"];
    
    // 使用父类方法设置返回按钮，而不是自定义
    [self setupBackButton];
    
    // 覆盖左边按钮的点击事件
    [self.leftButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.leftButton addTarget:self action:@selector(handleBackAction) forControlEvents:UIControlEventTouchUpInside];
    
    [self web];
    [self myProgressView];
    if (_url) {
        [self.web loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_url]]];
    }
}

// 设置自定义返回按钮
- (void)setupBackButton {
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setImage:[UIImage imageNamed:@"nav_back_n"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(handleBackAction) forControlEvents:UIControlEventTouchUpInside];
    backButton.frame = CGRectMake(0, 0, 44, 44);
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.navigationItem.leftBarButtonItem = backItem;
}

// 处理返回操作
- (void)handleBackAction {
    // 如果WebView可以返回，则回到上一页
    if (self.web.canGoBack) {
        [self.web goBack];
    } else {
        // 否则关闭整个控制器
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - WKNavigationDelegate
// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"开始加载页面");
}

// 页面加载完成时调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"页面加载完成");
    // 更新导航历史状态
    self.hasNavigationHistory = webView.canGoBack;
}

// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"页面加载失败: %@", error);
}

// 在发送请求之前，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    // 这里可以拦截特定链接，实现自定义处理
    decisionHandler(WKNavigationActionPolicyAllow);
}


#pragma mark - event response
// 计算wkWebView进度条
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.web && [keyPath isEqualToString:@"estimatedProgress"]) {
        CGFloat newprogress = [[change objectForKey:NSKeyValueChangeNewKey] doubleValue];
        self.myProgressView.alpha = 1.0f;
        [self.myProgressView setProgress:newprogress animated:YES];
        if (newprogress >= 1.0f) {
            [UIView animateWithDuration:0.3f
                                  delay:0.3f
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 self.myProgressView.alpha = 0.0f;
                             }
                             completion:^(BOOL finished) {
                                 [self.myProgressView setProgress:0 animated:NO];
                             }];
        }
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark - getter and setter
- (WKWebView *)web {
    if (!_web) {
        _web = [[WKWebView alloc] initWithFrame:({
            CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - NavigationBarHeight);
        }) configuration:({
            WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
            config.userContentController = [[WKUserContentController alloc] init];
            [config setPreferences:({
                WKPreferences *preferences = [WKPreferences new];
                preferences.javaScriptCanOpenWindowsAutomatically = YES;
                // html 页面中文字的最小字体大小
                preferences.minimumFontSize = 16.0;
                preferences;
            })];
            config;
        })];
        [_web addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
        [_web setUIDelegate:self];
        [_web setNavigationDelegate:self];
        [self.view addSubview:_web];
    }
    return _web;
}

- (UIProgressView *)myProgressView {
    if (_myProgressView == nil) {
        _myProgressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 0)];
        _myProgressView.tintColor = [UIColor greenColor];
        _myProgressView.trackTintColor = [UIColor whiteColor];
        _myProgressView.hidden = !_showProgress;
        [self.view addSubview:_myProgressView];
    }
    return _myProgressView;
}


#pragma mark - set
- (void)setShowProgress:(BOOL)showProgress {
    _showProgress = showProgress;
    if (showProgress == YES) {
        _myProgressView.hidden = NO;
    } else {
        _myProgressView.hidden = YES;
    }
}


#pragma mark - 系统
- (void)dealloc {
    [self.web removeObserver:self forKeyPath:@"estimatedProgress"];
}


@end
