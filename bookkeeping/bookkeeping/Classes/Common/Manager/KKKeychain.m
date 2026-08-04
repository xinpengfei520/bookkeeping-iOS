/**
 * Keychain 极简封装
 * 说明见 KKKeychain.h
 */

#import "KKKeychain.h"
#import <Security/Security.h>

// service 固定为 bundle id，与 key 一起构成条目的唯一标识
static NSString *KKKeychainService(void) {
    return [[NSBundle mainBundle] bundleIdentifier] ?: @"com.xpf.light.record";
}

static NSMutableDictionary *KKKeychainQuery(NSString *key) {
    return [@{
        (__bridge id)kSecClass:       (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: KKKeychainService(),
        (__bridge id)kSecAttrAccount: key,
    } mutableCopy];
}

@implementation KKKeychain

+ (BOOL)setString:(NSString *)value forKey:(NSString *)key {
    if (key.length == 0) {
        return NO;
    }
    if (value.length == 0) {
        [self removeKey:key];
        return YES;
    }
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];

    // 先尝试更新，条目不存在再新增（比先删后加少一次竞态窗口）
    NSMutableDictionary *query = KKKeychainQuery(key);
    NSDictionary *update = @{ (__bridge id)kSecValueData: data };
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query,
                                    (__bridge CFDictionaryRef)update);
    if (status == errSecItemNotFound) {
        NSMutableDictionary *add = KKKeychainQuery(key);
        add[(__bridge id)kSecValueData] = data;
        // AfterFirstUnlock：重启后首次解锁前不可读（后台刷新场景足够），且不进 iCloud 备份恢复到其它设备
        add[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlock;
        status = SecItemAdd((__bridge CFDictionaryRef)add, NULL);
    }
    if (status != errSecSuccess) {
        KKLog(@"[KKKeychain] set %@ failed: %d", key, (int)status);
    }
    return status == errSecSuccess;
}

+ (NSString *)stringForKey:(NSString *)key {
    if (key.length == 0) {
        return nil;
    }
    NSMutableDictionary *query = KKKeychainQuery(key);
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status != errSecSuccess || result == NULL) {
        return nil;
    }
    NSData *data = (__bridge_transfer NSData *)result;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (void)removeKey:(NSString *)key {
    if (key.length == 0) {
        return;
    }
    SecItemDelete((__bridge CFDictionaryRef)KKKeychainQuery(key));
}

@end
