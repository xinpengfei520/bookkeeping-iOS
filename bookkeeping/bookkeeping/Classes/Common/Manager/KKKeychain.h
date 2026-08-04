/**
 * Keychain 极简封装 —— 只做字符串的存 / 取 / 删
 *
 * 用途：登录 token 从 NSUserDefaults(App Group plist，明文落盘、随备份可读)
 * 迁到 Keychain。不设置 kSecAttrAccessGroup —— 用 App 自己的默认访问组，
 * 不需要任何付费开发者账号才有的 entitlement，免费签名也能跑。
 * （BookMonth widget 不发网络请求、不读 token，所以无需跨进程共享。）
 *
 * @author 2026-08-04 创建文件
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKKeychain : NSObject

/// 存字符串。value 为 nil / 空串等价于删除。返回是否成功。
+ (BOOL)setString:(nullable NSString *)value forKey:(NSString *)key;
/// 取字符串，没有时返回 nil
+ (nullable NSString *)stringForKey:(NSString *)key;
/// 删除
+ (void)removeKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
