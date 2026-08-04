/**
 * 用户信息
 * @author 郑业强 2018-11-20
 */

#import "UserInfo.h"

@implementation UserInfo

// 是否登录
+ (BOOL)isLogin {
    // 有缓存的 token 说明已经登录
    if ([self getAuthorizationToken]) {
        return YES;
    }
    return NO;
}

// 保存个人信息
+ (void)saveUserInfo:(NSDictionary *)param {
    [NSUserDefaults setObject:param forKey:kUser];
}

// 保存个人信息
+ (void)saveUserModel:(UserModel *)model {
    NSDictionary *param = [model mj_keyValues];
    [NSUserDefaults setObject:param forKey:kUser];
}

+ (void)saveAuthorizationTimestamp{
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval time = [date timeIntervalSince1970];
    NSString *timeString = [NSString stringWithFormat:@"%.0f", time];
    [NSUserDefaults setObject:timeString forKey:AUTHORIZATION_TIMESTAMP];
}

+ (void)saveAuthorizationExpiresIn:(NSInteger)expiresIn {
    if (expiresIn > 0) {
        [NSUserDefaults setObject:@(expiresIn) forKey:AUTHORIZATION_EXPIRES_IN];
    }
}

+ (BOOL)authorizationWillExpired{
    NSString *timeString = [NSUserDefaults objectForKey:AUTHORIZATION_TIMESTAMP];
    double timestamp = timeString.doubleValue;
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval currentTime = [date timeIntervalSince1970];
    // 服务端登录响应体会下发 expiresIn(秒)，用掉 80% 有效期后提前续签；
    // 拿不到 expiresIn 时（老 token、老响应）退回原来的"7 天有效期、第 6 天续签"。
    NSNumber *expiresIn = [NSUserDefaults objectForKey:AUTHORIZATION_EXPIRES_IN];
    NSTimeInterval threshold = ([expiresIn integerValue] > 0)
        ? [expiresIn doubleValue] * 0.8
        : 6*24*60*60;
    if ((currentTime - timestamp) > threshold) {
        return YES;
    }
    return NO;
}

/// 剥掉 `Bearer ` 前缀（大小写不敏感，容忍前后与中间的多余空白）。
/// 本地永远只存裸 JWT —— 双前缀 `Bearer Bearer eyJ...` 会被服务端拒绝，
/// 唯一可靠的写法是"存裸 token、发送时只拼一次前缀"。
+ (NSString *)stripBearerPrefix:(NSString *)value {
    NSString *token = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    while (token.length > 6 && [[token substringToIndex:6] caseInsensitiveCompare:@"Bearer"] == NSOrderedSame) {
        NSString *rest = [[token substringFromIndex:6] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (rest.length == 0) {
            break;
        }
        token = rest;
    }
    return token;
}

+ (void)saveAuthorizationToken:(NSString *)authorization{
    if (authorization.length == 0) {
        return;
    }
    NSString *token = [self stripBearerPrefix:authorization];
    if (token.length == 0) {
        return;
    }
    [NSUserDefaults setObject:token forKey:AUTHORIZATION_TOKEN];
}

+ (NSString *)getAuthorizationToken{
    NSString *token = [NSUserDefaults objectForKey:AUTHORIZATION_TOKEN];
    if (token.length == 0) {
        return nil;
    }
    // 升级安装：本地可能还留着改动前带 `Bearer ` 前缀的旧值，读取时补剥一次。
    return [self stripBearerPrefix:token];
}

+ (NSString *)getAuthorizationHeader{
    NSString *token = [self getAuthorizationToken];
    if (token.length == 0) {
        return nil;
    }
    return [NSString stringWithFormat:@"Bearer %@", token];
}

// 读取个人信息
+ (UserModel *)loadUserInfo {
    NSDictionary *param = (NSDictionary *)[NSUserDefaults objectForKey:kUser];
    UserModel *model = [UserModel mj_objectWithKeyValues:param];
    return model;
}

// 清除登录信息
+ (void)clearUserInfo {
    NSUserDefaults *sharedData = [[NSUserDefaults alloc] initWithSuiteName:@"group.xpf.widget"];
    [sharedData removeObjectForKey:kUser];
    [sharedData removeObjectForKey:AUTHORIZATION_TOKEN];
    [sharedData removeObjectForKey:AUTHORIZATION_TIMESTAMP];
    [sharedData removeObjectForKey:AUTHORIZATION_EXPIRES_IN];
    [sharedData removeObjectForKey:All_BOOK_LIST];
}


@end
