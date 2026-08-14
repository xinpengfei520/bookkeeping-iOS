//
//  KKLLMParser.h
//  bookkeeping
//
//  语音记账 M2：LLM 兜底解析器。
//  当规则解析器未能识别金额或类别时，异步请求后端 /book/parse 接口补全缺失字段。
//  始终在 2 秒内回调（超时或无网络时原样回调 entry）；所有回调均在主线程。
//

#import <Foundation/Foundation.h>

@class KKParsedBookEntry, BKCModel;

NS_ASSUME_NONNULL_BEGIN

@interface KKLLMParser : NSObject

/// 判断是否值得走 LLM：规则解析器未识别出金额或类别时返回 YES。
+ (BOOL)needsLLMForEntry:(KKParsedBookEntry *)entry;

/// 异步请求 LLM 兜底解析，将缺失字段就地合并进 entry，再回调。
/// - 超时（2 秒）或接口报错：entry 保持规则解析结果不变，直接回调。
/// - categories 用于把 LLM 返回的 categoryName 解析成本地 categoryId。
/// - completion 一定在主线程回调，且仅回调一次。
+ (void)fillEntry:(KKParsedBookEntry *)entry
       categories:(NSArray<BKCModel *> *)categories
       completion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
