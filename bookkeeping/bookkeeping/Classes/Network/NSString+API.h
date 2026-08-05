/**
 * 接口请求地址
 * @author 郑业强 2018-12-21 创建文件
 */

#import <Foundation/Foundation.h>

// 生产环境
#define KHost @"https://api.vance.xin"

// 测试环境
//#define KHost @"http://139.224.162.55:80"
#define kUser  @"kUser"
#define Request(A) [NSString stringWithFormat:@"%@%@", KHost, A]

// 新增记账
#define bookDetailSaveRequest Request(@"/book/detail/save")
// 删除记账
#define bookDetailDeleteRequest Request(@"/book/detail/delete")
// 修改记账
#define bookDetailUpdateRequest Request(@"/book/detail/update")
// 获取所有记账列表
#define allBookListRequest Request(@"/book/detail/list/all")
// 汇率(GET，可选 ?date=YYYY-MM-DD)。全平台统一取数，APP 不要自己接第三方汇率源
#define bookRatesRequest Request(@"/book/rates")
// 获取所有记账备注列表
#define bookMarkListRequest Request(@"/book/mark/list")
// 保存备注
#define saveMarkRequest Request(@"/book/mark/save")
// 修改备注
#define updateMarkRequest Request(@"/book/mark/update")
// 个人信息
#define userInfoRequest Request(@"/book/user/info")
// 修改个人信息
#define updateUserInfoRequest Request(@"/book/user/update")
// 上传头像
#define uploadAvatarRequest Request(@"/book/user/upload/avatar")
// 短信验证码
#define userSmsCodeRequest Request(@"/book/user/sms/code")
// 登录
#define userLoginRequest Request(@"/book/user/login")
// 退出登录
#define userLogoutRequest Request(@"/book/user/logout")
// 刷新 token
#define refreshTokenRequest Request(@"/book/user/refresh/token")
// 修改密码
#define ChangePassRequest Request(@"/book/user/password/update")
// 删除账号
#define DeleteAccountRequest Request(@"/book/user/delete/account")


// =================== Web 页面 / 外链 ===================
#define KWebHost @"https://book.vance.xin"
#define WebPage(A) [NSString stringWithFormat:@"%@%@", KWebHost, A]

// 登录页脚链接
#define kAgreementURL          WebPage(@"/agreement.html")
#define kPrivacyURL            WebPage(@"/privacy.html")
// 设置/关于的正式法律页（与登录页脚是不同文档，注意保留）
#define kTermsOfServiceURL     WebPage(@"/apps/jiya/legal/terms_of_service.html")
#define kPrivacyPolicyURL      WebPage(@"/apps/jiya/legal/privacy_policy.html")
// 帮助
#define kHelpURL               WebPage(@"/help_ios.html")
// App Store
#define kAppStoreURL           @"https://apps.apple.com/app/6739944920"
