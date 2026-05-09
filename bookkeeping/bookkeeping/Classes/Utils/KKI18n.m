//
//  KKI18n.m
//  bookkeeping
//

#import "KKI18n.h"

NSString * const KKLanguageCodeChinese = @"zh-Hans";
NSString * const KKLanguageCodeEnglish = @"en";
NSString * const KKLanguageDidChangeNotification = @"KKLanguageDidChangeNotification";

static NSString * const kKKLanguageDefaultsKey = @"kk_app_language";

/// Chinese → English. Populated in Phase 2C; missing entries fall back to
/// the Chinese key itself.
static NSDictionary<NSString *, NSString *> *KKEnglishTable(void) {
    static NSDictionary *table;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        table = @{
            // Phase 2A bootstrap — translations land in Phase 2C.
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
    NSString *code = [[NSUserDefaults standardUserDefaults] stringForKey:kKKLanguageDefaultsKey];
    return code.length > 0 ? code : nil;
}

+ (void)setUserPreferredLanguageCode:(NSString *)code {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (code.length > 0) {
        [defaults setObject:code forKey:kKKLanguageDefaultsKey];
    } else {
        [defaults removeObjectForKey:kKKLanguageDefaultsKey];
    }
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:KKLanguageDidChangeNotification object:nil];
}

@end
