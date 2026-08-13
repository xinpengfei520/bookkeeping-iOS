//
//  KKChineseNumber.h
//  bookkeeping
//
//  中文数字 → 数值。给语音记账的金额解析用（ASR 偶尔会把金额吐成中文数字）。
//  纯 Foundation，无任何 UI/存储依赖，单测在 ChineseNumberTests。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKChineseNumber : NSObject

/// 解析纯中文数字串：三十五 / 两百五 / 一千二 / 五百零三 / 十八 / 三十五点八 / 半。
/// 口语简写按习惯展开（两百五=250、一千二=1200、一万二=12000），
/// 带「零」则简写失效（三百零五=305）。解析失败返回 NAN。
+ (double)numberFromChinese:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
