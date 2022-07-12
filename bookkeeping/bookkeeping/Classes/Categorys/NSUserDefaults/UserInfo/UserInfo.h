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
// 保存授权 token
+ (void)saveAuthorizationToken:(NSString *)authorization;
// 获取授权 token
+ (NSString *)getAuthorizationToken;
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
