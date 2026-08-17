//
//  KKLLMParser.m
//  bookkeeping
//
//  解析策略：只补全规则解析器未能识别的字段，已有值不覆盖（用户原始话意优先）。
//  日期字段刻意不从 LLM 合并——规则解析器已良好处理相对/绝对日期，
//  LLM 返回的 YYYY-MM-DD 引入误差风险大于收益。
//

#import "KKLLMParser.h"
#import "KKBookTextParser.h"   // KKParsedBookEntry
#import "BKCIncomeModel.h"     // BKCModel

// LLM 兜底最长等待时间（秒）；超时后直接用规则解析结果，不阻塞交互
static const NSTimeInterval kLLMTimeoutSeconds = 2.0;

@implementation KKLLMParser

#pragma mark - 公开接口

+ (BOOL)needsLLMForEntry:(KKParsedBookEntry *)entry {
    return entry.price <= 0 || entry.categoryId == -1;
}

+ (void)fillEntry:(KKParsedBookEntry *)entry
       categories:(NSArray<BKCModel *> *)categories
       completion:(void (^)(void))completion {
    NSParameterAssert(completion);
    if (!completion) return;

    // 规则解析已完整 → 不需要 LLM
    if (![self needsLLMForEntry:entry]) {
        completion();
        return;
    }

    // __block 标志确保 completion 只回调一次（超时 or 网络响应，先到先得）
    __block BOOL responded = NO;
    NSString *text = entry.rawText ?: @"";
    // 后端 BookParseRequest.text 上限 500；OCR 原文可能更长，先截断再发。
    if (text.length > 500) {
        text = [text substringToIndex:500];
    }

    // 超时兜底：2 秒后若 LLM 仍未响应，直接用规则解析结果
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kLLMTimeoutSeconds * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (!responded) {
            responded = YES;
            completion();
        }
    });

    // 发起请求；AFNManager 自动注入 Authorization 头
    [AFNManager POST:bookParseRequest
              params:@{@"text": text}
            complete:^(APPResult *result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (responded) return;   // 已超时，丢弃结果
            responded = YES;
            if (result.code == BIZ_SUCCESS && [result.data isKindOfClass:[NSDictionary class]]) {
                [self mergeData:(NSDictionary *)result.data intoEntry:entry categories:categories];
            }
            completion();
        });
    }];
}

#pragma mark - 私有

// 仅补全规则解析器未能识别的字段
+ (void)mergeData:(NSDictionary *)data
        intoEntry:(KKParsedBookEntry *)entry
       categories:(NSArray<BKCModel *> *)categories {

    // 金额：仅在规则未解析出时采用
    if (entry.price <= 0) {
        double price = [data[@"price"] doubleValue];
        if (price > 0 && price <= 99999999) {
            entry.price = round(price * 100) / 100.0;
        }
    }

    // 类别：仅在规则未命中时尝试用 LLM 返回的 categoryName 匹配本地类别
    if (entry.categoryId == -1) {
        NSString *categoryName = data[@"categoryName"];
        BKCModel *matched = [self categoryNamed:categoryName inCategories:categories];
        if (matched) {
            entry.categoryId = matched.Id;
            entry.isIncome   = matched.is_income;
        } else if (data[@"isIncome"] != nil) {
            // 类别名未命中本地列表，但 LLM 至少确定了收支方向
            entry.isIncome = [data[@"isIncome"] boolValue];
        }
    }

    // 备注：仅在规则未提取出时补充
    if (entry.mark.length == 0) {
        NSString *mark = data[@"mark"];
        if (mark.length > 0) {
            entry.mark = mark.length > 20 ? [mark substringToIndex:20] : mark;
        }
    }

    // 日期：刻意不合并（见文件头注释）
}

// 先精确匹配，再前缀匹配（应对 LLM 返回的轻微变体，如"餐饮类" vs "餐饮"）
+ (nullable BKCModel *)categoryNamed:(NSString *)name
                        inCategories:(NSArray<BKCModel *> *)categories {
    if (!name.length) return nil;
    for (BKCModel *model in categories) {
        if ([model.name isEqualToString:name]) return model;
    }
    for (BKCModel *model in categories) {
        if (model.name.length && [name hasPrefix:model.name]) return model;
    }
    return nil;
}

@end
