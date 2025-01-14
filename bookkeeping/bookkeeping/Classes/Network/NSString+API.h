/**
 * 接口请求地址
 * @author 郑业强 2018-12-21 创建文件
 */

#import <Foundation/Foundation.h>

// 生产环境
#define KHost @"https://api.vance.xin"
#define KStatic(str) [NSString stringWithFormat:@"https://api.vance.xin/media/%@", str]

// 测试环境
//#define KHost @"http://139.224.162.55:80"
//#define KStatic(str) [NSString stringWithFormat:@"http://139.224.162.55:80/media/%@", str]
#define kUser  @"kUser"
#define Request(A) [NSString stringWithFormat:@"%@%@", KHost, A]



// 同步数据
#define SyncedDataRequest Request(@"/shayu/syncedDataRequest.action")
// 类别设置列表
#define CategorySetListRequest Request(@"/shayu/getCategorySetRequest.action")
// 全部类别
#define CategoryListRequest Request(@"/shayu/getCategoryRequest.action")
// 用户类别列表
#define CustomerCategoryListRequest Request(@"/shayu/getCustomerCategoryListRequest.action")
// 添加系统类别
#define AddSystemCategoryRequest Request(@"/shayu/addSystemCategoryRequest.action")
// 删除系统类别
#define RemoveSystemCategoryRequest Request(@"/shayu/removeSystemCategoryRequest.action")
// 添加用户类别
#define AddInsertCategoryListRequest Request(@"/shayu/addInsertCategoryRequest.action")
// 删除用户类别
#define RemoveInsertCategoryListRequest Request(@"/shayu/removeInsertCategoryRequest.action")
// 创建验证码
#define CreateCoderequest Request(@"/shayu/createCodeRequest.action")
// 验证验证码
#define ValidateCoderequest Request(@"/shayu/validateCodeRequest.action")
// 忘记密码
#define ForgetPassRequest Request(@"/shayu/forgetPassRequest.action")
// 绑定第三方账号
#define BindThirdRequest Request(@"/shayu/bindThirdRequest.action")
// 绑定手机号
#define BindPhoneRequest Request(@"/shayu/bindPhoneRequest.action")
// 声音
#define SoundRequest Request(@"/shayu/soundRequest.action")
// 详情
#define DetailRequest Request(@"/shayu/detailRequest.action")
// 定时列表
#define TimeListRequest Request(@"/shayu/timeListRequest.action")
// 添加定时
#define AddTimeRequest Request(@"/shayu/addTimeRequest.action")
// 删除定时
#define RemoveTimeRequest Request(@"/shayu/removeTimeRequest.action")
// 记账
#define CreateBookRequest Request(@"/shayu/createBookRequest.action")
// 查账(条)
#define GetBookListRequest Request(@"/shayu/getBookListRequest.action")
// 查账(组)
#define getBookGroupRequest Request(@"/shayu/getBookGroupRequest.action")

// 新增记账
#define bookDetailSaveRequest Request(@"/book/detail/save")
// 删除记账
#define bookDetailDeleteRequest Request(@"/book/detail/delete")
// 修改记账
#define bookDetailUpdateRequest Request(@"/book/detail/update")
// 获取所有记账列表
#define allBookListRequest Request(@"/book/detail/list/all")
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
