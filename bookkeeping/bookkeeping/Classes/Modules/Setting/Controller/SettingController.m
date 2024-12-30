#import <MessageUI/MessageUI.h>

// 在 @interface 中添加 MFMailComposeViewControllerDelegate
@interface SettingController () <MFMailComposeViewControllerDelegate>
// ... 其他代码保持不变
@end

@implementation SettingController

// ... 其他代码保持不变

#pragma mark - 意见反馈
- (void)feedbackClick {
    if (![MFMailComposeViewController canSendMail]) {
        [self showTextHUD:@"设备不支持发送邮件" delay:2.f];
        return;
    }
    
    MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
    mailVC.mailComposeDelegate = self;
    
    // 设置收件人
    [mailVC setToRecipients:@[@"your-email@example.com"]];
    
    // 设置主题
    [mailVC setSubject:@"记呀 - 意见反馈"];
    
    // 设置邮件内容
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    NSString *deviceModel = [[UIDevice currentDevice] model];
    
    NSString *emailBody = [NSString stringWithFormat:@"\n\n\n\n\n\n"
                          @"----------\n"
                          @"App版本：%@\n"
                          @"系统版本：iOS %@\n"
                          @"设备型号：%@\n",
                          appVersion, systemVersion, deviceModel];
    
    [mailVC setMessageBody:emailBody isHTML:NO];
    
    [self presentViewController:mailVC animated:YES completion:nil];
}

#pragma mark - MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller 
          didFinishWithResult:(MFMailComposeResult)result 
                        error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
    
    switch (result) {
        case MFMailComposeResultCancelled:
            NSLog(@"取消发送");
            break;
        case MFMailComposeResultSaved:
            [self showTextHUD:@"邮件已保存" delay:2.f];
            break;
        case MFMailComposeResultSent:
            [self showTextHUD:@"发送成功" delay:2.f];
            break;
        case MFMailComposeResultFailed:
            [self showTextHUD:@"发送失败" delay:2.f];
            break;
        default:
            break;
    }
}

#pragma mark - 邀请好友
- (void)inviteFriendsClick {
    // 准备分享内容
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"] ?: @"记呀";
    NSString *text = [NSString stringWithFormat:@"推荐一个好用的记账App：%@", appName];
    UIImage *image = [UIImage imageNamed:@"AppPreview"];
    NSURL *appUrl = [NSURL URLWithString:@"https://apps.apple.com/app/idxxxxxxxx"]; // 替换为你的App Store链接
    
    // 创建分享内容
    NSArray *activityItems = @[];
    if (text) {
        activityItems = [activityItems arrayByAddingObject:text];
    }
    if (image) {
        activityItems = [activityItems arrayByAddingObject:image];
    }
    if (appUrl) {
        activityItems = [activityItems arrayByAddingObject:appUrl];
    }
    
    // 创建分享控制器
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems 
                                                                           applicationActivities:nil];
    
    // 设置回调
    activityVC.completionWithItemsHandler = ^(UIActivityType activityType, 
                                            BOOL completed, 
                                            NSArray *returnedItems, 
                                            NSError *activityError) {
        if (completed) {
            [self showTextHUD:@"分享成功" delay:2.f];
        }
    };
    
    // 在 iPad 上需要设置弹出位置
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        activityVC.popoverPresentationController.sourceView = self.view;
        activityVC.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width/2, 
                                                                        self.view.bounds.size.height/2, 
                                                                        0, 
                                                                        0);
    }
    
    [self presentViewController:activityVC animated:YES completion:nil];
}
@end 