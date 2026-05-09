//
//  KKTheme.m
//  bookkeeping
//

#import "KKTheme.h"

NSString * const KKThemeModeLight = @"light";
NSString * const KKThemeModeDark  = @"dark";

static NSString * const kKKThemeDefaultsKey = @"kk_app_theme_mode";

/// Same shared suite used by KKI18n / NSUserDefaults+Extension / UserInfo.
static NSUserDefaults *KKThemeSharedDefaults(void) {
    static NSUserDefaults *defaults;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.xpf.widget"];
    });
    return defaults;
}

@implementation KKTheme

+ (NSString *)userPreferredMode {
    NSString *mode = [KKThemeSharedDefaults() stringForKey:kKKThemeDefaultsKey];
    return mode.length > 0 ? mode : nil;
}

+ (void)setUserPreferredMode:(NSString *)mode {
    NSUserDefaults *defaults = KKThemeSharedDefaults();
    if (mode.length > 0) {
        [defaults setObject:mode forKey:kKKThemeDefaultsKey];
    } else {
        [defaults removeObjectForKey:kKKThemeDefaultsKey];
    }
    [defaults synchronize];
}

+ (UIUserInterfaceStyle)effectiveStyle {
    NSString *mode = [self userPreferredMode];
    if ([mode isEqualToString:KKThemeModeLight]) return UIUserInterfaceStyleLight;
    if ([mode isEqualToString:KKThemeModeDark])  return UIUserInterfaceStyleDark;
    return UIUserInterfaceStyleUnspecified;
}

+ (void)applyToWindow:(UIWindow *)window {
    if (!window) return;
    window.overrideUserInterfaceStyle = [self effectiveStyle];
}

@end
