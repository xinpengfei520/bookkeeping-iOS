//
//  KKTheme.h
//  bookkeeping
//
//  Dark mode preference. Stored in shared App Group defaults so widget
//  could read it (currently widget rendering is not theme-driven).
//
//  Three-way switch:
//      nil / empty   → follow system (UIUserInterfaceStyleUnspecified)
//      "light"       → force light
//      "dark"        → force dark
//
//  Apply with [KKTheme applyToWindow:window]. AppDelegate calls this on
//  launch; the settings UI calls it on user toggle.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const KKThemeModeLight;        // @"light"
extern NSString * const KKThemeModeDark;         // @"dark"

@interface KKTheme : NSObject

/// nil means "follow system".
+ (nullable NSString *)userPreferredMode;

/// Pass nil to clear the override (= follow system).
+ (void)setUserPreferredMode:(nullable NSString *)mode;

/// Resolve the user pref to a concrete UIUserInterfaceStyle. Unspecified ==
/// follow system.
+ (UIUserInterfaceStyle)effectiveStyle;

/// Apply the current preference to a UIWindow. Safe to call repeatedly.
+ (void)applyToWindow:(nullable UIWindow *)window;

@end

NS_ASSUME_NONNULL_END
