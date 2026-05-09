//
//  KKI18n.m
//  bookkeeping
//

#import "KKI18n.h"

NSString * const KKLanguageCodeChinese = @"zh-Hans";
NSString * const KKLanguageCodeEnglish = @"en";
NSString * const KKLanguageDidChangeNotification = @"KKLanguageDidChangeNotification";

static NSString * const kKKLanguageDefaultsKey = @"kk_app_language";

/// Shared App Group defaults so widget reads the same preference as host.
/// Must match the suite used by NSUserDefaults+Extension / UserInfo.
static NSUserDefaults *KKSharedDefaults(void) {
    static NSUserDefaults *defaults;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.xpf.widget"];
    });
    return defaults;
}

/// Chinese → English translation table. Keys are the literal Chinese strings as
/// they appear in source. Missing entries fall back to the key itself (i.e.
/// degrade visibly to Chinese in en mode but never blank).
///
/// Notes on intentional pass-throughs:
///   - 简体中文 — language self-name, conventionally shown in native script
///     regardless of UI language (matches iOS Settings).
///   - 沪ICP备2022014461号-3A — Chinese ICP filing, legally required to display
///     in original form.
static NSDictionary<NSString *, NSString *> *KKEnglishTable(void) {
    static NSDictionary *table;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        table = @{
            // ---- Generic / shared ----
            @"确定": @"OK",
            @"取消": @"Cancel",
            @"完成": @"Done",
            @"删除": @"Delete",
            @"保存": @"Save",
            @"返回": @"Back",
            @"分享": @"Share",
            @"刷新": @"Refresh",
            @"警告": @"Warning",
            @"温馨提示": @"Reminder",
            @"今天": @"Today",
            @"昨天": @"Yesterday",
            // HomeHeader 用 KKLocalized(@"月") 作为 monthLab 旁边的小后缀。
            // 之前曾尝试 @"" 让英文模式不显示后缀，但 monthDescLab intrinsic
            // 尺寸坍缩到 0 会带动 XIB 里几个 centerY 锚定的元素飘移，导致用户
            // 反馈"布局高度变了"。给 en 一个短缩写保持视觉宽度。
            @"月": @"Mo.",

            // ---- Empty / loading / network states ----
            @"请求失败": @"Request failed",
            @"读取缓存成功": @"Cache loaded",
            @"网络竟然崩溃了": @"Network unavailable",
            @"别紧张, 试试看刷新页面~": @"Don't worry — pull to refresh",
            @"暂无数据": @"No data",
            @"可以去看看其他页面": @"Try another page",
            @"正在请求数据": @"Loading…",
            @"坐下喝口茶, 缓一缓~": @"Take it easy, sit back…",
            @"您还没有相关的订单": @"No orders yet",
            @"可以去看看有哪些想买的": @"Take a look at what's available",
            @"加载中…": @"Loading…",
            @"没有更多了": @"No more",
            @"同步数据...": @"Syncing data…",
            @"同步中...": @"Syncing…",
            @"修改中": @"Updating…",
            @"添加中...": @"Adding…",
            @"修改成功": @"Updated",
            @"空空如也～": @"Empty",

            // ---- Pull-to-refresh ----
            @"下拉刷新": @"Pull down to refresh",
            @"松开刷新": @"Release to refresh",
            @"上拉加载更多": @"Pull up to load more",
            @"松开加载更多": @"Release to load more",
            @"下拉查看下月数据": @"Pull down for next month",
            @"松开查看下月数据": @"Release for next month",
            @"上拉查看上月数据": @"Pull up for previous month",
            @"松开查看上月数据": @"Release for previous month",
            @"查找数据中": @"Loading…",
            @"下拉关闭页面": @"Pull down to close",
            @"松开关闭页面": @"Release to close",

            // ---- Auth / verification / accounts ----
            @"面容 ID 短时间内失败多次，需要验证手机密码": @"Face ID failed too many times — please enter your passcode",
            @"请把你的手指放到Home键上": @"Place your finger on the Home button",
            @"修改密码": @"Change password",
            @"旧密码": @"Old password",
            @"请输入旧密码": @"Enter old password",
            @"新密码": @"New password",
            @"6-18位数字、字母组合": @"6–18 letters or digits",
            @"确认密码": @"Confirm password",
            @"请再次输入密码": @"Re-enter password",
            @"确认修改": @"Confirm",
            @"两次密码不一致": @"Passwords don't match",
            @"密码长度为6-18位": @"Password must be 6–18 characters",
            @"验证码": @"Verification code",
            @"请输入验证码": @"Enter verification code",
            @"验证": @"Verify",
            @"重新发送": @"Resend",
            @"重新获取": @"Resend",
            @"获取验证码": @"Get code",
            @"验证码已发送": @"Code sent",
            @"%lds后重新发送": @"Resend in %lds",
            @"%02lds重新获取": @"Resend in %02lds",
            @"验证码登录": @"Code sign-in",
            @"密码登录": @"Password sign-in",
            @"请输入手机号": @"Enter phone number",
            @"请输入密码": @"Enter password",
            @"下一步": @"Next",
            @"登录": @"Sign in",
            @"注册": @"Sign up",
            @"找回密码": @"Forgot password",
            @"绑定账号": @"Link account",
            @"我已阅读并同意": @"I have read and agree to",
            @"未注册的手机号将自动注册": @"Unregistered phone numbers are signed up automatically",
            @"用户协议": @"Terms of Service",
            @"隐私政策": @"Privacy Policy",
            @"隐私协议": @"Privacy Policy",
            @"退出登录": @"Sign out",
            @"确定退出当前帐号吗？": @"Sign out of this account?",

            // ---- Account deletion ----
            @"删除账号": @"Delete account",
            @"你正在进行删除账号操作": @"You're about to delete your account",
            @"账号一旦删除，将无法恢复。请务必仔细思考，谨慎操作。": @"This action cannot be undone. Please proceed with caution.",
            @"- 删除账号后，您的所有数据将被清除，包括账单记录、预算设置等；": @"- All your data will be erased, including bill records and budget settings.",
            @"- 删除账号后，您将无法找回任何历史数据；": @"- You will not be able to recover any historical data.",
            @"- 删除账号后，您可以使用相同的手机号重新注册，但之前的数据无法恢复。": @"- You may register a new account with the same phone number, but previous data cannot be restored.",
            @"申请删除": @"Submit",
            @"我再想想": @"Let me think",
            @"删除后账号将无法恢复，确定要删除吗？": @"This will permanently delete your account. Continue?",
            @"账号已删除": @"Account deleted",

            // ---- Category management ----
            @"类别设置": @"Categories",
            @"添加类别": @"Add category",
            @"删除类别会同时删除该类别下的所有历史收支记录": @"Deleting this category will also delete all related entries",
            @"(自定义)": @"(Custom)",
            @"类别名称不能为空": @"Category name can't be empty",

            // ---- Reminders ----
            @"定时提醒": @"Reminders",
            @"你还没有任何提醒哦～": @"No reminders yet",
            @"已经添加过该时间的提醒": @"Already added a reminder for this time",
            @"每天": @"Daily",
            @"添加提醒": @"Add reminder",
            @"提醒时间": @"Reminder time",
            @"记账时间到了，赶紧记一笔吧！": @"Time to log an entry!",

            // ---- Profile ----
            @"个人信息": @"Profile",
            @"头像": @"Avatar",
            @"昵称": @"Nickname",
            @"性别": @"Gender",
            @"手机号": @"Phone",
            @"邮箱": @"Email",
            @"未绑定": @"Not set",
            @"男": @"Male",
            @"女": @"Female",
            @"修改昵称": @"Change nickname",
            @"昵称不能为空": @"Nickname can't be empty",
            @"请输入2-8位昵称": @"Enter a nickname (2–8 chars)",
            @"修改手机号": @"Change phone",
            @"手机号不能为空": @"Phone number can't be empty",
            @"请输入11位新手机号": @"Enter 11-digit phone number",
            @"修改邮箱": @"Change email",
            @"邮箱不能为空": @"Email can't be empty",
            @"邮箱格式不正确": @"Invalid email format",
            @"请输入邮箱地址": @"Enter email address",
            @"拍照": @"Take photo",
            @"从相册选择": @"Choose from library",
            @"当前设备不支持拍照": @"Camera not available",

            // ---- Date / time / calendar ----
            @"选择日期": @"Select date",
            @"%02ld月%02ld日   %@": @"%02ld/%02ld   %@",
            @"%ld年%02ld月%02ld日   %@": @"%ld-%02ld-%02ld   %@",
            @"%ld年": @"%ld",
            @"%ld月": @"%ld",
            @"%d月": @"%d",
            @"本周": @"This week",
            @"%02ld周": @"Week %02ld",
            @"%ld年%02ld周": @"%ld Week %02ld",
            @"本月": @"This month",
            @"%02ld月": @"%02ld",
            @"%ld年%02ld月": @"%ld-%02ld",
            @"今年": @"This year",
            @"yyyy年MM月": @"MMM yyyy",
            @"%@加入": @"Joined %@",
            @"星期日": @"Sun",
            @"星期一": @"Mon",
            @"星期二": @"Tue",
            @"星期三": @"Wed",
            @"星期四": @"Thu",
            @"星期五": @"Fri",
            @"星期六": @"Sat",
            @"%.0f分钟前": @"%.0fm ago",
            @"%.0f小时前": @"%.0fh ago",
            @"%d天前": @"%dd ago",
            @"%d个月前": @"%dmo ago",
            @"1年前": @"1y ago",
            @"%d年前": @"%dy ago",
            @"1小时前": @"1h ago",
            @"%@天%@时%@分%@秒": @"%@d %@h %@m %@s",

            // ---- Bills / chart ----
            @"账单": @"Bills",
            @"明细": @"Details",
            @"收入: %@": @"Income: %@",
            @"支出: %@": @"Expense: %@",
            @"收入": @"Income",
            @"支出": @"Expense",
            @"支出排行榜": @"Top expenses",
            @"收入排行榜": @"Top income",
            @"平均值: %0.2f": @"Avg: %0.2f",
            @"总支出: %0.2f": @"Total expense: %0.2f",
            @"总收入: %0.2f": @"Total income: %0.2f",
            @"最大3笔交易": @"Top 3 transactions",
            @"没有费用": @"No transactions",

            // ---- Booking flow ----
            @"记账": @"Add entry",
            @"记一笔": @"New entry",
            @"类型": @"Type",
            @"金额": @"Amount",
            @"日期": @"Date",
            @"备注": @"Note",
            @"推荐备注": @"Suggested notes",
            @"请输入金额": @"Enter amount",

            // ---- Search ----
            @"关键字不能为空": @"Keyword can't be empty",
            @"类别/备注/金额": @"Category / Note / Amount",

            // ---- Export ----
            @"导出数据": @"Export data",
            @"点击导出数据到文件": @"Tap to export data",
            @"日期,类别,金额,收支类型,备注\n": @"Date,Category,Amount,Type,Note\n",
            @"记账导出_%@.csv": @"Bookkeeping_export_%@.csv",
            @"导出失败": @"Export failed",
            @"导出成功，活动类型: %@": @"Exported via: %@",
            @"导出成功": @"Exported",
            @"导出过程中出现错误": @"Export error",
            @"已取消导出": @"Export cancelled",

            // ---- Feedback / sharing ----
            @"反馈": @"Feedback",
            @"请输入您的问题": @"Enter your message",
            @"记呀 - 意见反馈": @"Jiya — Feedback",
            @"App版本：%@\n": @"App version: %@\n",
            @"系统版本：iOS %@\n": @"iOS version: %@\n",
            @"设备型号：%@\n": @"Device: %@\n",
            @"无法打开邮件应用": @"Can't open Mail app",
            @"设备不支持发送邮件": @"This device can't send email",
            @"推荐一个好用的记账App：%@": @"Try this great bookkeeping app: %@",
            @"分享成功": @"Shared",
            @"微信": @"WeChat",
            @"朋友圈": @"Moments",

            // ---- Language / theme settings ----
            @"语言": @"Language",
            @"跟随系统": @"Follow System",
            @"语言已切换": @"Language changed",
            @"需要重启 App 后完全生效。": @"Restart the app for changes to take full effect.",
            @"立即重启": @"Restart now",
            @"稍后": @"Later",
            @"深色模式": @"Dark Mode",
            @"浅色": @"Light",
            @"深色": @"Dark",

            // ---- Me page ----
            @"我的": @"Me",
            @"未登录": @"Not signed in",
            @"期待你加入": @"Sign in to get started",
            @"我的账单": @"My bills",
            @"面容解锁": @"Face ID lock",
            @"邀请好友": @"Invite a friend",
            @"意见反馈": @"Feedback",
            @"记账总天数": @"Days logged",
            @"记账总笔数": @"Entries",
            @"设置": @"Settings",
            @"帮助": @"Help",
            @"关于": @"About",

            // ---- Intentional pass-throughs ----
            @"记呀": @"Jiya",
            @"简体中文": @"简体中文",
            @"沪ICP备2022014461号-3A": @"沪ICP备2022014461号-3A",
        };
    });
    return table;
}

@implementation KKI18n

+ (NSString *)stringForKey:(NSString *)key {
    if (key.length == 0) return key ?: @"";
    NSString *code = [self effectiveLanguageCode];
    if ([code isEqualToString:KKLanguageCodeEnglish]) {
        NSString *value = KKEnglishTable()[key];
        return value ?: key;
    }
    return key;  // Chinese mode — key is the Chinese
}

+ (NSString *)effectiveLanguageCode {
    NSString *pref = [self userPreferredLanguageCode];
    if (pref.length > 0) return pref;
    NSString *system = [[NSLocale preferredLanguages] firstObject] ?: @"en";
    if ([system hasPrefix:@"zh"]) return KKLanguageCodeChinese;
    return KKLanguageCodeEnglish;
}

+ (NSString *)userPreferredLanguageCode {
    NSString *code = [KKSharedDefaults() stringForKey:kKKLanguageDefaultsKey];
    return code.length > 0 ? code : nil;
}

+ (void)setUserPreferredLanguageCode:(NSString *)code {
    NSUserDefaults *defaults = KKSharedDefaults();
    if (code.length > 0) {
        [defaults setObject:code forKey:kKKLanguageDefaultsKey];
    } else {
        [defaults removeObjectForKey:kKKLanguageDefaultsKey];
    }
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:KKLanguageDidChangeNotification object:nil];
}

@end
