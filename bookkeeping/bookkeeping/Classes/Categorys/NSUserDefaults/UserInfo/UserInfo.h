/**
 * 用户信息
 * @author 郑业强 2018-11-20
 */

#import <Foundation/Foundation.h>
#import "UserModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface UserInfo : NSObject

// 是否登录
+ (BOOL)isLogin;

// 保存个人信息
+ (void)saveUserInfo:(NSDictionary *)param;
// 保存个人信息
+ (void)saveUserModel:(UserModel *)model;
/// 保存授权 token。
/// 入参允许是裸 JWT，也允许带 `Bearer ` 前缀（大小写不敏感、容忍多余空白）——
/// 前缀会在这里被剥掉，本地**只存裸 JWT**。
+ (void)saveAuthorizationToken:(NSString *)authorization;
/// 获取裸 JWT（不含 `Bearer ` 前缀）。
/// 老版本升级上来时本地可能存的是带前缀的旧值，这里读取时也会剥一次，保证不被登出。
+ (NSString *)getAuthorizationToken;
/// 获取可直接塞进请求头的值：`Bearer <裸 JWT>`。网络层统一用这个，前缀只拼一次。
+ (NSString *)getAuthorizationHeader;
/// 保存服务端下发的 token 有效期(秒)，登录响应体的 `expiresIn`
+ (void)saveAuthorizationExpiresIn:(NSInteger)expiresIn;
// 读取个人信息
+ (UserModel *)loadUserInfo;
// 清除登录信息
+ (void)clearUserInfo;
// 保存 token 的时间戳
+ (void)saveAuthorizationTimestamp;
// token 是否将要过期
+ (BOOL)authorizationWillExpired;

@end

NS_ASSUME_NONNULL_END
