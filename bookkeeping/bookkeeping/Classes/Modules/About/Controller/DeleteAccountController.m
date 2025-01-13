/**
 * 删除账号
 */

#import "DeleteAccountController.h"
#import "AgreementWebViewController.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface DeleteAccountController()


@end

#pragma mark - 实现
@implementation DeleteAccountController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = NO;
    self.hbd_barTintColor = kColor_Main_Color;
    [self setNavTitle:@"删除账号"];
    [self setupUI];
    [self setupConstraints];
}

#pragma mark - 初始化UI
- (void)setupUI {
    
}

#pragma mark - 设置约束
- (void)setupConstraints {
    
}

@end
