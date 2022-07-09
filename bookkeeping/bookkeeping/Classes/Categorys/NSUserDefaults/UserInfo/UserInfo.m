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

+ (void)saveAuthorizationToken:(NSString *)authorization{
    NSLog(@"authorization: %@", authorization);
    if (authorization) {
        [NSUserDefaults setObject:authorization forKey:AUTHORIZATION_TOKEN];
    }
}

+ (NSString *)getAuthorizationToken{
    return [NSUserDefaults objectForKey:AUTHORIZATION_TOKEN];
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
    [sharedData removeObjectForKey:All_BOOK_LIST];
}


@end
