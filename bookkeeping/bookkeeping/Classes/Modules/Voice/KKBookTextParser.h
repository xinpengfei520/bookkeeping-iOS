//
//  KKBookTextParser.h
//  bookkeeping
//
//  语音记账的规则解析器：一句口语 → 结构化记账字段。
//  纯 Foundation 逻辑（不碰 UI、不碰网络），单测在 BookTextParserTests；
//  以后遇到解析不准的话术，先在测试里加用例，再回来改规则。
//

#import <Foundation/Foundation.h>

@class BKCModel;
@class MarkModel;

NS_ASSUME_NONNULL_BEGIN

/// 解析结果。price==0 表示没听出金额；categoryId==-1 表示没匹配到类别 ——
/// 两者都不算失败，确认卡片会让用户补，绝不静默丢弃。
@interface KKParsedBookEntry : NSObject

@property (nonatomic, assign) double price;          // 人民币金额，0 = 未解析出
@property (nonatomic, assign) NSInteger categoryId;  // -1 = 未匹配
@property (nonatomic, assign) BOOL isIncome;         // 匹配到类别时以类别方向为准
@property (nonatomic, assign) NSInteger year;
@property (nonatomic, assign) NSInteger month;
@property (nonatomic, assign) NSInteger day;
@property (nonatomic, copy  ) NSString *mark;        // 优先用分类下已有备注，否则收缩成关键词
@property (nonatomic, copy  ) NSString *rawText;     // 原始识别文本，确认卡片回显用

@end


@interface KKBookTextParser : NSObject

/// 解析一句话。categories 传用户当前启用的类别（含自定义）；
/// referenceDate 是「今天」的基准（正常传 [NSDate date]，测试传固定日期）。
+ (KKParsedBookEntry *)parseText:(NSString *)text
                      categories:(NSArray<BKCModel *> *)categories
                   referenceDate:(NSDate *)referenceDate;

/// 带推荐备注的解析。命中分类后，若原文包含该分类下某条 markName（最长优先），
/// 就用那条已有备注；否则把口令填充词剥掉，收成一个短关键词。
+ (KKParsedBookEntry *)parseText:(NSString *)text
                      categories:(NSArray<BKCModel *> *)categories
                           marks:(nullable NSArray<MarkModel *> *)marks
                   referenceDate:(NSDate *)referenceDate;

/// 账单 / 支付截图 OCR 文本 → 0~N 条记账。
/// 保留换行，按「带日期的列表行 / 合计金额 / 单笔支付」分流；
/// 后端 /book/parse 的 multi 尚未上线，多条主要靠这一层。
+ (NSArray<KKParsedBookEntry *> *)parseReceiptText:(NSString *)text
                                        categories:(NSArray<BKCModel *> *)categories
                                             marks:(nullable NSArray<MarkModel *> *)marks
                                     referenceDate:(NSDate *)referenceDate;

/// 用户当前启用的类别（系统保留 + 自定义，支出在前收入在后），
/// 与 BookController 记账键盘展示的集合一致。
+ (NSArray<BKCModel *> *)activeCategories;

@end

NS_ASSUME_NONNULL_END
