//
//  KKI18n.h
//  bookkeeping
//
//  In-memory localization. Keys ARE the Chinese strings as they appear in
//  source (e.g. KKLocalized(@"完成")). The English table maps Chinese → English;
//  Chinese mode is a no-op pass-through. Missing keys fall back to the key
//  itself, so unmigrated strings degrade to Chinese in en mode — visibly off,
//  but never blank.
//
//  Switching language only flips the user-preference key and posts a
//  notification — the caller is responsible for prompting the user to
//  restart the app (UIKit reads many strings during view lifecycle, so live
//  re-rendering is not in scope).
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Stored values. Empty/nil means "follow system locale".
extern NSString * const KKLanguageCodeChinese;        // @"zh-Hans"
extern NSString * const KKLanguageCodeEnglish;        // @"en"

extern NSString * const KKLanguageDidChangeNotification;

@interface KKI18n : NSObject

/// Look up a string by its Chinese key. Returns the localized version for the
/// effective language; falls back to the key itself if the entry is missing.
+ (NSString *)stringForKey:(NSString *)key;

/// What's actually in effect right now: @"zh-Hans" or @"en". Never nil.
/// Consults user preference, falls back to system locale.
+ (NSString *)effectiveLanguageCode;

/// User's stored preference. nil = follow system.
+ (nullable NSString *)userPreferredLanguageCode;

/// Persist user's choice. Pass nil for "follow system". Posts
/// KKLanguageDidChangeNotification. Does NOT restart the app.
+ (void)setUserPreferredLanguageCode:(nullable NSString *)code;

@end

NS_ASSUME_NONNULL_END
