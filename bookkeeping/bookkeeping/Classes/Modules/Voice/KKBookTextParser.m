//
//  KKBookTextParser.m
//  bookkeeping
//
//  解析顺序刻意固定为：日期 → 金额 → 类别 → 备注。
//  日期必须先于金额提取，否则「8月3号」的数字会被当成金额。
//

#import "KKBookTextParser.h"
#import "KKChineseNumber.h"
#import "BKCIncomeModel.h"
#import "MarkModel.h"

#pragma mark - KKParsedBookEntry

@implementation KKParsedBookEntry
@end


#pragma mark - 私有工具

// 中文数字字符集（含小数点「点」），正则里复用
#define KK_CN_NUM @"[零〇一二两三四五六七八九十百千万亿点]"

static NSRegularExpression *KKRegex(NSString *pattern) {
    static NSMutableDictionary<NSString *, NSRegularExpression *> *cache;
    static NSLock *lock;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ cache = [NSMutableDictionary dictionary]; lock = [[NSLock alloc] init]; });
    [lock lock];
    NSRegularExpression *regex = cache[pattern];
    if (!regex) {
        regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:NULL];
        cache[pattern] = regex;
    }
    [lock unlock];
    return regex;
}

// 单个中文/阿拉伯数字字符 → 数值（金额的「毛/角」尾数用）
static NSInteger KKSingleDigit(NSString *s) {
    if (s.length != 1) return -1;
    unichar c = [s characterAtIndex:0];
    if (c >= '1' && c <= '9') return c - '0';
    double v = [KKChineseNumber numberFromChinese:s];
    return isnan(v) ? -1 : (NSInteger)v;
}

// 金额候选
@interface KKAmountCandidate : NSObject
@property (nonatomic, assign) double value;
@property (nonatomic, assign) BOOL hasUnit;
@property (nonatomic, assign) NSRange range;
@end
@implementation KKAmountCandidate
@end

// 账单 OCR 行上的日期 / 金额
@interface KKReceiptDateHit : NSObject
@property (nonatomic, assign) NSInteger year;
@property (nonatomic, assign) NSInteger month;
@property (nonatomic, assign) NSInteger day;
@property (nonatomic, assign) NSRange range;
@end
@implementation KKReceiptDateHit
@end

@interface KKReceiptAmountHit : NSObject
@property (nonatomic, assign) double value;
@property (nonatomic, assign) NSRange range;
@property (nonatomic, assign) BOOL isTotal;
@property (nonatomic, assign) BOOL hasUnit;
@end
@implementation KKReceiptAmountHit
@end

@interface KKReceiptLine : NSObject
@property (nonatomic, copy  ) NSString *text;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) KKReceiptDateHit *date;
@property (nonatomic, strong) KKReceiptAmountHit *amount;
@property (nonatomic, copy  ) NSString *leftover;
@property (nonatomic, assign) BOOL isBoilerplate;
@end
@implementation KKReceiptLine
@end


#pragma mark - KKBookTextParser

@implementation KKBookTextParser

#pragma mark 日期

// 提取日期短语并从 work 中删除。返回 YES 表示句子里说了日期。
// dayOffset 模式：*absolute=NO，*offset 为相对今天的天数；
// 绝对模式：*absolute=YES，*month/*day 生效（年份取基准年）。
+ (BOOL)extractDateFrom:(NSMutableString *)work
               absolute:(BOOL *)absolute offset:(NSInteger *)offset
                  month:(NSInteger *)month day:(NSInteger *)day {
    // 相对日期：注意「大前天」必须先于「前天」匹配
    NSArray *relatives = @[@[@"大前天", @-3], @[@"前天", @-2], @[@"昨天", @-1], @[@"今天", @0], @[@"今儿", @0]];
    for (NSArray *pair in relatives) {
        NSRange r = [work rangeOfString:pair[0]];
        if (r.location != NSNotFound) {
            [work deleteCharactersInRange:r];
            *absolute = NO; *offset = [pair[1] integerValue];
            return YES;
        }
    }
    // 绝对日期：8月3号 / 八月三号 / 3号
    NSTextCheckingResult *m1 = [KKRegex(@"(\\d{1,2})月(\\d{1,2})[号日]") firstMatchInString:work options:0 range:NSMakeRange(0, work.length)];
    if (m1) {
        NSInteger mo = [[work substringWithRange:[m1 rangeAtIndex:1]] integerValue];
        NSInteger d = [[work substringWithRange:[m1 rangeAtIndex:2]] integerValue];
        if (mo >= 1 && mo <= 12 && d >= 1 && d <= 31) {
            [work deleteCharactersInRange:m1.range];
            *absolute = YES; *month = mo; *day = d;
            return YES;
        }
    }
    NSTextCheckingResult *m2 = [KKRegex(@"([一二三四五六七八九十]{1,3})月([一二三四五六七八九十]{1,3})[号日]") firstMatchInString:work options:0 range:NSMakeRange(0, work.length)];
    if (m2) {
        double mo = [KKChineseNumber numberFromChinese:[work substringWithRange:[m2 rangeAtIndex:1]]];
        double d = [KKChineseNumber numberFromChinese:[work substringWithRange:[m2 rangeAtIndex:2]]];
        if (!isnan(mo) && !isnan(d) && mo >= 1 && mo <= 12 && d >= 1 && d <= 31) {
            [work deleteCharactersInRange:m2.range];
            *absolute = YES; *month = (NSInteger)mo; *day = (NSInteger)d;
            return YES;
        }
    }
    NSTextCheckingResult *m3 = [KKRegex(@"(\\d{1,2})[号日]") firstMatchInString:work options:0 range:NSMakeRange(0, work.length)];
    if (m3) {
        NSInteger d = [[work substringWithRange:[m3 rangeAtIndex:1]] integerValue];
        if (d >= 1 && d <= 31) {
            [work deleteCharactersInRange:m3.range];
            *absolute = YES; *month = 0; *day = d;   // month=0 表示「本月 d 号」
            return YES;
        }
    }
    return NO;
}

#pragma mark 金额

// 按优先级收集金额候选（带货币单位的优先，同级取句尾最近的），
// 命中后把该候选从 work 中删除。没解析出返回 0。
+ (double)extractAmountFrom:(NSMutableString *)work {
    NSMutableArray<KKAmountCandidate *> *unitful = [NSMutableArray array];
    NSMutableArray<KKAmountCandidate *> *bare = [NSMutableArray array];

    BOOL (^overlaps)(NSRange) = ^BOOL(NSRange r) {
        for (KKAmountCandidate *c in unitful) {
            if (NSIntersectionRange(c.range, r).length > 0) return YES;
        }
        return NO;
    };
    void (^add)(NSMutableArray *, double, BOOL, NSRange) = ^(NSMutableArray *arr, double v, BOOL u, NSRange r) {
        if (isnan(v) || v <= 0 || v > 99999999) return;
        KKAmountCandidate *c = [[KKAmountCandidate alloc] init];
        c.value = v; c.hasUnit = u; c.range = r;
        [arr addObject:c];
    };
    NSRange full = NSMakeRange(0, work.length);

    // A1: 35块 / 35.5元 / 35块8 / 35块八毛
    [KKRegex(@"(\\d+(?:\\.\\d+)?)(?:块钱|块|元|人民币)(?:([1-9一二两三四五六七八九])(?:毛|角)?)?")
     enumerateMatchesInString:work options:0 range:full usingBlock:^(NSTextCheckingResult *m, NSMatchingFlags f, BOOL *stop) {
        double v = [[work substringWithRange:[m rangeAtIndex:1]] doubleValue];
        if ([m rangeAtIndex:2].location != NSNotFound) {
            NSInteger d = KKSingleDigit([work substringWithRange:[m rangeAtIndex:2]]);
            if (d > 0) v += d / 10.0;
        }
        add(unitful, v, YES, m.range);
    }];
    // A2: 1万2 / 3千5（口语大额，money 语境下视为带单位）
    [KKRegex(@"(\\d+(?:\\.\\d+)?)万([1-9])?") enumerateMatchesInString:work options:0 range:full usingBlock:^(NSTextCheckingResult *m, NSMatchingFlags f, BOOL *stop) {
        if (overlaps(m.range)) return;
        double v = [[work substringWithRange:[m rangeAtIndex:1]] doubleValue] * 10000;
        if ([m rangeAtIndex:2].location != NSNotFound) v += [[work substringWithRange:[m rangeAtIndex:2]] doubleValue] * 1000;
        add(unitful, v, YES, m.range);
    }];
    [KKRegex(@"(\\d+(?:\\.\\d+)?)千([1-9])?") enumerateMatchesInString:work options:0 range:full usingBlock:^(NSTextCheckingResult *m, NSMatchingFlags f, BOOL *stop) {
        if (overlaps(m.range)) return;
        double v = [[work substringWithRange:[m rangeAtIndex:1]] doubleValue] * 1000;
        if ([m rangeAtIndex:2].location != NSNotFound) v += [[work substringWithRange:[m rangeAtIndex:2]] doubleValue] * 100;
        add(unitful, v, YES, m.range);
    }];
    // A3: 5毛 / 3.5角
    [KKRegex(@"(\\d+(?:\\.\\d+)?)[毛角]") enumerateMatchesInString:work options:0 range:full usingBlock:^(NSTextCheckingResult *m, NSMatchingFlags f, BOOL *stop) {
        if (overlaps(m.range)) return;
        add(unitful, [[work substringWithRange:[m rangeAtIndex:1]] doubleValue] / 10.0, YES, m.range);
    }];
    // C1: 三十五块八 / 两百五块 / 三块半 / 三块五毛
    [KKRegex(@"(" KK_CN_NUM @"+)(?:块钱|块|元)(半|[1-9一二两三四五六七八九](?:毛|角)?)?")
     enumerateMatchesInString:work options:0 range:full usingBlock:^(NSTextCheckingResult *m, NSMatchingFlags f, BOOL *stop) {
        if (overlaps(m.range)) return;
        double v = [KKChineseNumber numberFromChinese:[work substringWithRange:[m rangeAtIndex:1]]];
        if (isnan(v)) return;
        if ([m rangeAtIndex:2].location != NSNotFound) {
            NSString *extra = [work substringWithRange:[m rangeAtIndex:2]];
            if ([extra hasPrefix:@"半"]) {
                v += 0.5;
            } else {
                NSInteger d = KKSingleDigit([extra substringToIndex:1]);
                if (d > 0) v += d / 10.0;
            }
        }
        add(unitful, v, YES, m.range);
    }];
    // C2: 五毛 / 八角
    [KKRegex(@"([一二两三四五六七八九])[毛角]") enumerateMatchesInString:work options:0 range:full usingBlock:^(NSTextCheckingResult *m, NSMatchingFlags f, BOOL *stop) {
        if (overlaps(m.range)) return;
        NSInteger d = KKSingleDigit([work substringWithRange:[m rangeAtIndex:1]]);
        if (d > 0) add(unitful, d / 10.0, YES, m.range);
    }];
    // B1: 裸阿拉伯数字（没带单位，取句尾最近的）
    [KKRegex(@"\\d+(?:\\.\\d+)?") enumerateMatchesInString:work options:0 range:full usingBlock:^(NSTextCheckingResult *m, NSMatchingFlags f, BOOL *stop) {
        if (overlaps(m.range)) return;
        add(bare, [[work substringWithRange:m.range] doubleValue], NO, m.range);
    }];
    // B2: 动词后面跟的裸中文数字（花了三十五）。裸中文数字不带动词约束误报太多（一起/三里屯）
    [KKRegex(@"(?:花了|花掉|用了|付了|支付了|消费了|消费|收了|收到|赚了|挣了|收入)(" KK_CN_NUM @"+)")
     enumerateMatchesInString:work options:0 range:full usingBlock:^(NSTextCheckingResult *m, NSMatchingFlags f, BOOL *stop) {
        NSRange r = [m rangeAtIndex:1];
        if (overlaps(r)) return;
        add(bare, [KKChineseNumber numberFromChinese:[work substringWithRange:r]], NO, r);
    }];

    // 选择：带单位的取最后一个；都没带单位也取最后一个
    NSArray<KKAmountCandidate *> *pool = unitful.count ? unitful : bare;
    KKAmountCandidate *chosen = nil;
    for (KKAmountCandidate *c in pool) {
        if (!chosen || c.range.location > chosen.range.location) chosen = c;
    }
    if (!chosen) return 0;
    [work deleteCharactersInRange:chosen.range];
    return round(chosen.value * 100) / 100.0;
}

#pragma mark 类别

// 同义词表：口语关键词 → SC.plist 的类别名。顺序即优先级（长词在前避免误吞）。
// 只增不删；解析不准先在 BookTextParserTests 加用例。
+ (NSArray<NSArray<NSString *> *> *)synonymTable {
    static NSArray *table;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSDictionary<NSString *, NSArray<NSString *> *> *groups = @{
            @"餐饮": @[@"早饭", @"早餐", @"早点", @"午饭", @"午餐", @"中饭", @"晚饭", @"晚餐", @"夜宵", @"宵夜", @"外卖", @"吃饭", @"聚餐", @"下馆子", @"咖啡", @"奶茶", @"火锅", @"烧烤", @"食堂", @"麦当劳", @"肯德基", @"星巴克", @"瑞幸"],
            @"交通": @[@"打车", @"打的", @"滴滴出行", @"滴滴", @"出租车", @"地铁", @"公交", @"高铁", @"火车票", @"机票", @"加油", @"停车", @"过路费", @"共享单车"],
            @"购物": @[@"淘宝", @"京东", @"拼多多", @"网购", @"买东西", @"超市", @"商场"],
            @"日用": @[@"纸巾", @"洗发水", @"牙膏", @"洗衣液", @"沐浴露", @"日用品"],
            @"蔬菜": @[@"买菜", @"青菜", @"蔬菜"],
            @"水果": @[@"水果", @"西瓜", @"香蕉", @"橘子", @"葡萄", @"草莓"],
            @"零食": @[@"零食", @"瓜子", @"薯片", @"饼干"],
            @"运动": @[@"健身", @"游泳", @"跑步", @"瑜伽"],
            @"娱乐": @[@"电影", @"KTV", @"唱歌", @"游戏", @"演唱会", @"门票"],
            @"通讯": @[@"话费", @"流量", @"宽带", @"手机费"],
            @"服饰": @[@"衣服", @"裤子", @"鞋子", @"买鞋", @"外套", @"羽绒服"],
            @"美容": @[@"理发", @"剪头发", @"剪发", @"烫发", @"化妆品", @"护肤品", @"美甲"],
            @"住房": @[@"房租", @"房贷", @"物业费", @"水电费", @"水费", @"电费", @"燃气费", @"取暖费"],
            @"居家": @[@"家具", @"家电", @"被子", @"床单"],
            @"社交": @[@"请客", @"聚会", @"份子钱"],
            @"旅行": @[@"旅游", @"酒店", @"民宿", @"景点"],
            @"烟酒": @[@"香烟", @"买烟", @"啤酒", @"白酒", @"红酒"],
            @"数码": @[@"手机", @"耳机", @"电脑", @"键盘", @"鼠标", @"充电器", @"平板"],
            @"医疗": @[@"看病", @"买药", @"药店", @"医院", @"挂号", @"体检", @"打针"],
            @"书籍": @[@"买书", @"书店"],
            @"学习": @[@"网课", @"课程", @"培训", @"报班", @"学费"],
            @"信用卡": @[@"还信用卡", @"信用卡还款"],
            @"礼物": @[@"礼物", @"送礼"],
            @"亲友": @[@"给爸妈", @"给父母", @"孝敬"],
            @"维修": @[@"修车", @"维修", @"修理", @"修手机"],
            @"快递": @[@"快递", @"邮费", @"运费", @"寄件"],
            @"养生": @[@"按摩", @"足疗", @"泡脚"],
            @"工资": @[@"工资", @"发工资", @"薪水", @"月薪", @"发薪"],
            @"兼职": @[@"兼职", @"外快", @"副业"],
            @"理财": @[@"利息", @"基金", @"股票", @"分红", @"理财收益"],
            @"报销": @[@"报销"],
            @"退货": @[@"退款", @"退货"],
            @"出售": @[@"卖了", @"卖掉", @"出售", @"闲鱼"],
            @"红包": @[@"红包"],
        };
        NSMutableArray *pairs = [NSMutableArray array];
        [groups enumerateKeysAndObjectsUsingBlock:^(NSString *canonical, NSArray<NSString *> *keywords, BOOL *stop) {
            for (NSString *kw in keywords) [pairs addObject:@[kw, canonical]];
        }];
        // 长关键词优先（剪头发 先于 剪发），同长按字典序保证确定性
        [pairs sortUsingComparator:^NSComparisonResult(NSArray *a, NSArray *b) {
            if ([a[0] length] != [b[0] length]) return [a[0] length] > [b[0] length] ? NSOrderedAscending : NSOrderedDescending;
            return [a[0] compare:b[0]];
        }];
        table = pairs;
    });
    return table;
}

// 返回命中的类别；无命中返回 nil。candidates 顺序保持 categories 原序（支出在前），
// 同名双方向（红包/礼金）用 incomeHint 裁决。
+ (BKCModel *)matchCategoryIn:(NSString *)text categories:(NSArray<BKCModel *> *)categories incomeHint:(BOOL)incomeHint {
    // 第一层：类别名（含用户自定义）直接出现在句子里，取名字最长的一组
    NSMutableArray<BKCModel *> *hits = [NSMutableArray array];
    NSUInteger bestLen = 0;
    for (BKCModel *model in categories) {
        if (model.name.length == 0) continue;
        if (![text containsString:model.name]) continue;
        if (model.name.length > bestLen) {
            bestLen = model.name.length;
            [hits removeAllObjects];
        }
        if (model.name.length == bestLen) [hits addObject:model];
    }
    // 第二层：同义词 → 类别名
    if (hits.count == 0) {
        for (NSArray<NSString *> *pair in [self synonymTable]) {
            if (![text containsString:pair[0]]) continue;
            for (BKCModel *model in categories) {
                if ([model.name isEqualToString:pair[1]]) [hits addObject:model];
            }
            if (hits.count) break;   // 第一个能落到用户类别上的关键词生效
        }
    }
    if (hits.count == 0) return nil;
    for (BKCModel *model in hits) {
        if (model.is_income == incomeHint) return model;
    }
    return hits.firstObject;   // 双方向都不合 hint 时取支出版本（categories 支出在前）
}

+ (BOOL)incomeHintIn:(NSString *)text {
    static NSArray<NSString *> *hints;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        hints = @[@"收到", @"收入", @"入账", @"进账", @"工资", @"薪水", @"报销", @"退款", @"退货",
                  @"赚了", @"挣了", @"兼职", @"利息", @"分红", @"卖了", @"卖掉", @"出售", @"领了"];
    });
    for (NSString *hint in hints) {
        if ([text containsString:hint]) return YES;
    }
    return NO;
}

#pragma mark 备注

+ (NSArray<NSString *> *)markFillers {
    // 长词在前。含语音口令（记一下 / 帮我记），避免整句掉进备注。
    return @[@"帮我记一下", @"给我记一下", @"帮我记一笔", @"给我记一笔",
             @"帮我记账", @"给我记账", @"记一下", @"记一笔", @"记一记",
             @"帮我记", @"给我记", @"人民币", @"块钱", @"一共", @"总共",
             @"大概", @"大约", @"差不多",
             @"花掉了", @"花掉", @"花了", @"花费", @"用掉", @"用了", @"付了",
             @"支付了", @"支付", @"消费了", @"消费", @"支出了", @"支出",
             @"收到了", @"收到", @"收了", @"记账", @"记个"];
}

+ (NSString *)keywordFromLeftover:(NSString *)text categoryName:(NSString *)categoryName {
    NSMutableString *mark = [(text ?: @"") mutableCopy];
    for (NSString *filler in [self markFillers]) {
        [mark replaceOccurrencesOfString:filler withString:@"" options:0 range:NSMakeRange(0, mark.length)];
    }
    if (categoryName.length) {
        [mark replaceOccurrencesOfString:categoryName withString:@"" options:0 range:NSMakeRange(0, mark.length)];
    }
    NSMutableCharacterSet *trim = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [trim addCharactersInString:@"，。！？、,.!?~；;：:的了我在就还也又都块元毛角"];
    NSString *result = [mark stringByTrimmingCharactersInSet:trim];
    // 关键词宜短；确认卡片还能手改。20 是提交上限兜底。
    if (result.length > 10) result = [result substringToIndex:10];
    return result;
}

// 优先用该分类下已有备注（原文包含即命中，最长优先）；
// 否则用本类同义词当关键词；再否则把口令剥掉收成短词。
+ (NSString *)refineMarkFrom:(NSString *)leftover
                    category:(BKCModel *)category
                       marks:(NSArray<MarkModel *> *)marks {
    NSString *haystack = leftover ?: @"";
    if (haystack.length == 0) return @"";

    NSMutableArray<MarkModel *> *candidates = [NSMutableArray array];
    for (MarkModel *m in marks) {
        if (m.markName.length < 2) continue;
        if (category && m.categoryId != category.Id) continue;
        if ([haystack containsString:m.markName]) [candidates addObject:m];
    }
    if (candidates.count) {
        [candidates sortUsingComparator:^NSComparisonResult(MarkModel *a, MarkModel *b) {
            if (a.markName.length != b.markName.length) {
                return a.markName.length > b.markName.length ? NSOrderedAscending : NSOrderedDescending;
            }
            if (a.frequency != b.frequency) {
                return a.frequency > b.frequency ? NSOrderedAscending : NSOrderedDescending;
            }
            return [a.markName compare:b.markName];
        }];
        return candidates.firstObject.markName;
    }

    if (category.name.length) {
        for (NSArray<NSString *> *pair in [self synonymTable]) {
            if (![pair[1] isEqualToString:category.name]) continue;
            if ([pair[0] length] >= 2 && [haystack containsString:pair[0]]) {
                return pair[0];
            }
        }
    }

    return [self keywordFromLeftover:haystack categoryName:category.name];
}

#pragma mark 主入口

+ (KKParsedBookEntry *)parseText:(NSString *)text
                      categories:(NSArray<BKCModel *> *)categories
                   referenceDate:(NSDate *)referenceDate {
    return [self parseText:text categories:categories marks:nil referenceDate:referenceDate];
}

+ (KKParsedBookEntry *)parseText:(NSString *)text
                      categories:(NSArray<BKCModel *> *)categories
                           marks:(NSArray<MarkModel *> *)marks
                   referenceDate:(NSDate *)referenceDate {
    KKParsedBookEntry *entry = [[KKParsedBookEntry alloc] init];
    entry.rawText = text ?: @"";
    entry.categoryId = -1;

    // 归一化：全角转半角、去掉所有空白（中文 ASR 的空格没有语义）
    NSMutableString *work = [(text ?: @"") mutableCopy];
    CFStringTransform((__bridge CFMutableStringRef)work, NULL, kCFStringTransformFullwidthHalfwidth, false);
    work = [[[work componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsJoinedByString:@""] mutableCopy];

    // 1. 日期（必须先于金额，否则「8月3号」会被当金额）
    BOOL absolute = NO;
    NSInteger offset = 0, month = 0, day = 0;
    BOOL hasDate = [self extractDateFrom:work absolute:&absolute offset:&offset month:&month day:&day];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *targetDate = referenceDate;
    if (hasDate && !absolute && offset != 0) {
        targetDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:offset toDate:referenceDate options:0] ?: referenceDate;
    }
    NSDateComponents *comp = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:targetDate];
    entry.year = comp.year;
    entry.month = comp.month;
    entry.day = comp.day;
    if (hasDate && absolute) {
        if (month > 0) entry.month = month;   // month=0 表示「本月 d 号」
        entry.day = day;
    }

    // 2. 金额
    entry.price = [self extractAmountFrom:work];

    // 3. 类别（在剔除日期/金额后的文本上匹配；方向以类别为准）
    BOOL incomeHint = [self incomeHintIn:work];
    BKCModel *category = [self matchCategoryIn:work categories:categories incomeHint:incomeHint];
    if (category) {
        entry.categoryId = category.Id;
        entry.isIncome = category.is_income;
    } else {
        entry.isIncome = incomeHint;
    }

    // 4. 备注：先套该分类下已有备注，套不上再收成关键词
    entry.mark = [self refineMarkFrom:work category:category marks:marks];
    return entry;
}

#pragma mark 账单 OCR

+ (BOOL)receiptLineIsBoilerplate:(NSString *)line {
    static NSArray<NSString *> *exact;
    static NSArray<NSString *> *prefixes;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        exact = @[@"支付成功", @"交易成功", @"支付完成", @"已付款", @"微信支付", @"支付宝",
                  @"收款成功", @"转账成功", @"普通账单", @"账单详情", @"交易详情", @"订单详情",
                  @"当前状态", @"支付时间", @"交易时间", @"创建时间", @"商品详情", @"查看详情",
                  @"完成", @"关闭", @"复制", @"优惠券", @"积分", @"礼品卡", @"零钱",
                  @"银行卡", @"余额宝", @"花呗", @"信用卡"];
        prefixes = @[@"订单号", @"交易单号", @"商户单号", @"支付方式", @"当前状态"];
    });
    if ([exact containsObject:line]) return YES;
    for (NSString *p in prefixes) {
        if ([line hasPrefix:p]) return YES;
    }
    return NO;
}

+ (NSArray<KKReceiptDateHit *> *)receiptDatesInLine:(NSString *)line {
    NSMutableArray *hits = [NSMutableArray array];
    NSRange full = NSMakeRange(0, line.length);
    // 2026-08-13 / 2026/08/13 / 2026.08.13 / 2026年8月13日
    [KKRegex(@"(\\d{4})[-/.年](\\d{1,2})[-/.月](\\d{1,2})日?")
     enumerateMatchesInString:line options:0 range:full usingBlock:^(NSTextCheckingResult *m, NSMatchingFlags f, BOOL *stop) {
        NSInteger y = [[line substringWithRange:[m rangeAtIndex:1]] integerValue];
        NSInteger mo = [[line substringWithRange:[m rangeAtIndex:2]] integerValue];
        NSInteger d = [[line substringWithRange:[m rangeAtIndex:3]] integerValue];
        if (y < 2000 || y > 2100 || mo < 1 || mo > 12 || d < 1 || d > 31) return;
        KKReceiptDateHit *hit = [[KKReceiptDateHit alloc] init];
        hit.year = y; hit.month = mo; hit.day = d; hit.range = m.range;
        [hits addObject:hit];
    }];
    // 8月13日 / 08-13 / 08/13（不用点号，避免 38.00 被当成日期）
    [KKRegex(@"(?<!\\d)(\\d{1,2})[-/月](\\d{1,2})日?(?!\\d)")
     enumerateMatchesInString:line options:0 range:full usingBlock:^(NSTextCheckingResult *m, NSMatchingFlags f, BOOL *stop) {
        for (KKReceiptDateHit *exist in hits) {
            if (NSIntersectionRange(exist.range, m.range).length > 0) return;
        }
        NSInteger mo = [[line substringWithRange:[m rangeAtIndex:1]] integerValue];
        NSInteger d = [[line substringWithRange:[m rangeAtIndex:2]] integerValue];
        if (mo < 1 || mo > 12 || d < 1 || d > 31) return;
        KKReceiptDateHit *hit = [[KKReceiptDateHit alloc] init];
        hit.year = 0; hit.month = mo; hit.day = d; hit.range = m.range;
        [hits addObject:hit];
    }];
    return hits;
}

+ (double)receiptMoneyValue:(NSString *)raw {
    NSString *clean = [[raw stringByReplacingOccurrencesOfString:@"," withString:@""]
                       stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([clean hasPrefix:@"-"] || [clean hasPrefix:@"+"]) {
        clean = [clean substringFromIndex:1];
    }
    return [clean doubleValue];
}

+ (BOOL)receiptPrefixLooksLikeTotal:(NSString *)prefix {
    static NSArray<NSString *> *keys;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        keys = @[@"合计", @"总计", @"共计", @"实付金额", @"应付金额", @"支付金额",
                 @"收款金额", @"转账金额", @"订单金额", @"消费金额", @"实付", @"应付", @"金额"];
    });
    for (NSString *k in keys) {
        if ([prefix containsString:k]) return YES;
    }
    return NO;
}

+ (NSArray<KKReceiptAmountHit *> *)receiptAmountsInLine:(NSString *)line masked:(NSString *)masked {
    NSMutableArray *hits = [NSMutableArray array];
    NSRange full = NSMakeRange(0, masked.length);
    NSMutableIndexSet *used = [NSMutableIndexSet indexSet];
    void (^add)(double, NSRange, BOOL) = ^(double v, NSRange r, BOOL unit) {
        if (v <= 0 || v > 99999999) return;
        if ([used intersectsIndexesInRange:r]) return;
        // 没带货币符号的 4 位整数很像年份 / 单号，丢掉
        if (!unit && r.length >= 4 && v == (NSInteger)v && v >= 1000 && v <= 2100) return;
        if (!unit && r.length >= 8 && v == (NSInteger)v) return;
        KKReceiptAmountHit *hit = [[KKReceiptAmountHit alloc] init];
        hit.value = round(v * 100) / 100.0;
        hit.range = r;
        hit.hasUnit = unit;
        NSString *prefix = r.location < line.length ? [line substringToIndex:MIN(r.location, line.length)] : @"";
        hit.isTotal = [self receiptPrefixLooksLikeTotal:prefix];
        [hits addObject:hit];
        [used addIndexesInRange:r];
    };

    // ¥38.00 / ￥1,280.50 / -¥38
    [KKRegex(@"[-+]?[¥￥]\\s*(\\d{1,3}(?:,\\d{3})*(?:\\.\\d{1,2})?|\\d+(?:\\.\\d{1,2})?)")
     enumerateMatchesInString:masked options:0 range:full usingBlock:^(NSTextCheckingResult *m, NSMatchingFlags f, BOOL *stop) {
        add([self receiptMoneyValue:[masked substringWithRange:[m rangeAtIndex:1]]], m.range, YES);
    }];
    // 38.00元 / 38元
    [KKRegex(@"(\\d{1,3}(?:,\\d{3})*(?:\\.\\d{1,2})?|\\d+(?:\\.\\d{1,2})?)\\s*元")
     enumerateMatchesInString:masked options:0 range:full usingBlock:^(NSTextCheckingResult *m, NSMatchingFlags f, BOOL *stop) {
        add([self receiptMoneyValue:[masked substringWithRange:[m rangeAtIndex:1]]], m.range, YES);
    }];
    // 独立的 xx.xx（账单最常见）
    [KKRegex(@"(?<![\\d.])(\\d{1,3}(?:,\\d{3})*\\.\\d{2}|\\d+\\.\\d{2})(?![\\d.])")
     enumerateMatchesInString:masked options:0 range:full usingBlock:^(NSTextCheckingResult *m, NSMatchingFlags f, BOOL *stop) {
        add([self receiptMoneyValue:[masked substringWithRange:[m rangeAtIndex:1]]], m.range, NO);
    }];
    return hits;
}

+ (NSString *)maskReceiptLine:(NSString *)line dates:(NSArray<KKReceiptDateHit *> *)dates {
    NSMutableString *masked = [line mutableCopy];
    // 先盖住时间 14:32 / 14:32:10，避免被当成金额
    [KKRegex(@"\\d{1,2}:\\d{2}(?::\\d{2})?")
     enumerateMatchesInString:line options:0 range:NSMakeRange(0, line.length) usingBlock:^(NSTextCheckingResult *m, NSMatchingFlags f, BOOL *stop) {
        for (NSUInteger i = 0; i < m.range.length; i++) {
            [masked replaceCharactersInRange:NSMakeRange(m.range.location + i, 1) withString:@" "];
        }
    }];
    for (KKReceiptDateHit *d in dates) {
        for (NSUInteger i = 0; i < d.range.length && d.range.location + i < masked.length; i++) {
            [masked replaceCharactersInRange:NSMakeRange(d.range.location + i, 1) withString:@" "];
        }
    }
    return masked;
}

+ (NSString *)leftoverFromReceiptLine:(NSString *)line
                                dates:(NSArray<KKReceiptDateHit *> *)dates
                              amounts:(NSArray<KKReceiptAmountHit *> *)amounts {
    NSMutableString *work = [line mutableCopy];
    NSMutableArray *ranges = [NSMutableArray array];
    for (KKReceiptDateHit *d in dates) [ranges addObject:[NSValue valueWithRange:d.range]];
    for (KKReceiptAmountHit *a in amounts) [ranges addObject:[NSValue valueWithRange:a.range]];
    [ranges sortUsingComparator:^NSComparisonResult(NSValue *a, NSValue *b) {
        NSRange ra = a.rangeValue, rb = b.rangeValue;
        if (ra.location > rb.location) return NSOrderedAscending;
        if (ra.location < rb.location) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    for (NSValue *v in ranges) {
        NSRange r = v.rangeValue;
        if (r.location + r.length <= work.length) {
            [work replaceCharactersInRange:r withString:@""];
        }
    }
    static NSArray<NSString *> *labels;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        labels = @[@"合计", @"总计", @"共计", @"实付金额", @"应付金额", @"支付金额",
                   @"收款金额", @"转账金额", @"订单金额", @"消费金额", @"实付", @"应付",
                   @"金额", @"收款方", @"商户", @"店名", @"向", @"付款"];
    });
    for (NSString *lab in labels) {
        [work replaceOccurrencesOfString:lab withString:@"" options:0 range:NSMakeRange(0, work.length)];
    }
    NSMutableCharacterSet *trim = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [trim addCharactersInString:@"：:：,，。.-_/\\|"];
    return [work stringByTrimmingCharactersInSet:trim];
}

+ (KKParsedBookEntry *)receiptEntryWithPrice:(double)price
                                        year:(NSInteger)year month:(NSInteger)month day:(NSInteger)day
                                  markSource:(NSString *)markSource
                                     rawText:(NSString *)rawText
                                  categories:(NSArray<BKCModel *> *)categories
                                       marks:(NSArray<MarkModel *> *)marks {
    KKParsedBookEntry *entry = [[KKParsedBookEntry alloc] init];
    entry.price = price;
    entry.year = year;
    entry.month = month;
    entry.day = day;
    entry.categoryId = -1;
    entry.rawText = rawText ?: @"";
    NSString *hay = [(markSource.length ? markSource : rawText) ?: @"" copy];
    BOOL incomeHint = [self incomeHintIn:hay];
    BKCModel *category = [self matchCategoryIn:hay categories:categories incomeHint:incomeHint];
    if (!category && rawText.length) {
        category = [self matchCategoryIn:rawText categories:categories incomeHint:incomeHint];
    }
    if (category) {
        entry.categoryId = category.Id;
        entry.isIncome = category.is_income;
    } else {
        entry.isIncome = incomeHint;
    }
    entry.mark = [self refineMarkFrom:hay category:category marks:marks];
    return entry;
}

+ (NSArray<KKParsedBookEntry *> *)parseReceiptText:(NSString *)text
                                        categories:(NSArray<BKCModel *> *)categories
                                             marks:(NSArray<MarkModel *> *)marks
                                     referenceDate:(NSDate *)referenceDate {
    if (text.length == 0) return @[];
    NSMutableString *work = [text mutableCopy];
    CFStringTransform((__bridge CFMutableStringRef)work, NULL, kCFStringTransformFullwidthHalfwidth, false);
    NSArray<NSString *> *rawLines = [work componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *refComp = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                            fromDate:referenceDate ?: [NSDate date]];

    NSMutableArray<KKReceiptLine *> *lines = [NSMutableArray array];
    for (NSUInteger i = 0; i < rawLines.count; i++) {
        NSString *t = [rawLines[i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (t.length == 0) continue;
        KKReceiptLine *line = [[KKReceiptLine alloc] init];
        line.text = t;
        line.index = (NSInteger)i;
        line.isBoilerplate = [self receiptLineIsBoilerplate:t];
        NSArray<KKReceiptDateHit *> *dates = [self receiptDatesInLine:t];
        line.date = dates.firstObject;
        NSString *masked = [self maskReceiptLine:t dates:dates];
        NSArray<KKReceiptAmountHit *> *amounts = [self receiptAmountsInLine:t masked:masked];
        // 一行多个金额时：带合计标签的优先，否则取最后一个（账单行金额通常在行尾）
        KKReceiptAmountHit *chosen = nil;
        for (KKReceiptAmountHit *a in amounts) {
            if (a.isTotal) { chosen = a; break; }
        }
        if (!chosen) chosen = amounts.lastObject;
        line.amount = chosen;
        line.leftover = [self leftoverFromReceiptLine:t dates:dates amounts:chosen ? @[chosen] : @[]];
        [lines addObject:line];
    }

    // 上一行是「合计/金额」而本行只有数字：把合计标到本行金额上
    for (NSInteger i = 1; i < (NSInteger)lines.count; i++) {
        KKReceiptLine *cur = lines[i];
        KKReceiptLine *prev = lines[i - 1];
        if (cur.amount && !cur.amount.isTotal && prev.leftover.length == 0 &&
            [self receiptPrefixLooksLikeTotal:prev.text]) {
            cur.amount.isTotal = YES;
        }
    }

    NSMutableArray<KKReceiptLine *> *datedRows = [NSMutableArray array];
    NSMutableArray<KKReceiptLine *> *listRows = [NSMutableArray array];
    KKReceiptLine *totalLine = nil;
    for (KKReceiptLine *line in lines) {
        if (!line.amount) continue;
        if (line.amount.isTotal && !totalLine) totalLine = line;
        BOOL hasName = line.leftover.length >= 2 && !line.isBoilerplate;
        if (line.date && (hasName || line.leftover.length > 0)) {
            [datedRows addObject:line];
        }
        if (hasName || line.date) {
            [listRows addObject:line];
        }
    }

    NSMutableArray<KKParsedBookEntry *> *entries = [NSMutableArray array];
    void (^fillDate)(KKParsedBookEntry *, KKReceiptDateHit *) = ^(KKParsedBookEntry *e, KKReceiptDateHit *d) {
        e.year = refComp.year;
        e.month = refComp.month;
        e.day = refComp.day;
        if (!d) return;
        if (d.year > 0) e.year = d.year;
        e.month = d.month;
        e.day = d.day;
    };

    // 多笔账单列表：至少两行各自带日期+金额（微信/支付宝账单页）
    if (datedRows.count >= 2) {
        KKReceiptDateHit *carry = nil;
        for (KKReceiptLine *line in datedRows) {
            if (line.date) carry = line.date;
            KKParsedBookEntry *e = [self receiptEntryWithPrice:line.amount.value
                                                          year:refComp.year month:refComp.month day:refComp.day
                                                    markSource:line.leftover
                                                       rawText:line.text
                                                    categories:categories
                                                         marks:marks];
            fillDate(e, line.date ?: carry);
            [entries addObject:e];
        }
        return entries;
    }

    // 有合计：整张小票记一笔（行项目是明细，不拆）
    if (totalLine) {
        KKReceiptDateHit *date = totalLine.date;
        NSString *merchant = nil;
        for (KKReceiptLine *line in lines) {
            if (line.date && !date) date = line.date;
            if (merchant.length) continue;
            NSTextCheckingResult *m = [KKRegex(@"(?:收款方|商户|店名)[:：]?\\s*(.+)")
                                       firstMatchInString:line.text options:0 range:NSMakeRange(0, line.text.length)];
            if (m && [m rangeAtIndex:1].length) {
                merchant = [line.text substringWithRange:[m rangeAtIndex:1]];
                continue;
            }
            m = [KKRegex(@"向(.+)付款") firstMatchInString:line.text options:0 range:NSMakeRange(0, line.text.length)];
            if (m && [m rangeAtIndex:1].length) {
                merchant = [line.text substringWithRange:[m rangeAtIndex:1]];
                continue;
            }
            if (!line.isBoilerplate && !line.amount && line.leftover.length >= 2) {
                merchant = line.leftover;
            }
        }
        NSString *markSource = merchant.length ? merchant : (totalLine.leftover ?: @"");
        KKParsedBookEntry *e = [self receiptEntryWithPrice:totalLine.amount.value
                                                      year:refComp.year month:refComp.month day:refComp.day
                                                markSource:markSource
                                                   rawText:work
                                                categories:categories
                                                     marks:marks];
        fillDate(e, date);
        return @[e];
    }

    // 两行以上「商户 + 金额」（没写日期的流水）
    if (listRows.count >= 2) {
        KKReceiptDateHit *carry = nil;
        for (KKReceiptLine *line in listRows) {
            if (line.date) carry = line.date;
            KKParsedBookEntry *e = [self receiptEntryWithPrice:line.amount.value
                                                          year:refComp.year month:refComp.month day:refComp.day
                                                    markSource:line.leftover
                                                       rawText:line.text
                                                    categories:categories
                                                         marks:marks];
            fillDate(e, line.date ?: carry);
            [entries addObject:e];
        }
        return entries;
    }

    // 单笔：取带货币符号的金额，否则最后一个金额
    KKReceiptLine *single = nil;
    for (KKReceiptLine *line in lines) {
        if (!line.amount) continue;
        if (line.amount.hasUnit) { single = line; break; }
        single = line;
    }
    if (!single) return @[];

    KKReceiptDateHit *date = single.date;
    NSString *merchant = single.leftover;
    for (KKReceiptLine *line in lines) {
        if (line.date && !date) date = line.date;
        if (merchant.length >= 2) continue;
        if (!line.isBoilerplate && !line.amount && line.leftover.length >= 2) {
            merchant = line.leftover;
        }
    }
    KKParsedBookEntry *e = [self receiptEntryWithPrice:single.amount.value
                                                  year:refComp.year month:refComp.month day:refComp.day
                                            markSource:merchant
                                               rawText:work
                                            categories:categories
                                                 marks:marks];
    fillDate(e, date);
    return @[e];
}

#pragma mark 类别数据源

+ (NSArray<BKCModel *> *)activeCategories {
    // 与 BookController initData 同一拼法：系统保留 + 自定义，支出在前收入在后
    NSMutableArray *raw = [NSMutableArray array];
    for (NSString *key in @[PIN_CATE_SYS_HAS_PAY, PIN_CATE_CUS_HAS_PAY, PIN_CATE_SYS_HAS_INCOME, PIN_CATE_CUS_HAS_INCOME]) {
        NSArray *arr = [NSUserDefaults objectForKey:key];
        if (arr.count) [raw addObjectsFromArray:arr];
    }
    NSArray *models = [BKCModel mj_objectArrayWithKeyValuesArray:raw];
    return models ?: @[];
}

@end
