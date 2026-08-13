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
            @"餐饮": @[@"早饭", @"早餐", @"早点", @"午饭", @"午餐", @"中饭", @"晚饭", @"晚餐", @"夜宵", @"宵夜", @"外卖", @"吃饭", @"聚餐", @"下馆子", @"咖啡", @"奶茶", @"火锅", @"烧烤", @"食堂", @"麦当劳", @"肯德基"],
            @"交通": @[@"打车", @"打的", @"滴滴", @"出租车", @"地铁", @"公交", @"高铁", @"火车票", @"机票", @"加油", @"停车", @"过路费", @"共享单车"],
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

+ (NSString *)markFrom:(NSString *)text {
    NSMutableString *mark = [text mutableCopy];
    // 语气/动词填充词，全局剔除（长词在前）
    NSArray *fillers = @[@"人民币", @"块钱", @"一共", @"总共", @"大概", @"大约", @"差不多",
                         @"花掉了", @"花掉", @"花了", @"花费", @"用掉", @"用了", @"付了",
                         @"支付了", @"支付", @"消费了", @"消费", @"支出了", @"支出",
                         @"收到了", @"收到", @"收了", @"记一笔", @"记账", @"帮我记"];
    for (NSString *filler in fillers) {
        [mark replaceOccurrencesOfString:filler withString:@"" options:0 range:NSMakeRange(0, mark.length)];
    }
    // 两端修剪：标点、空白、残留的单位/助词
    NSMutableCharacterSet *trim = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [trim addCharactersInString:@"，。！？、,.!?~；;：:的了我在就还也又都块元毛角"];
    NSString *result = [mark stringByTrimmingCharactersInSet:trim];
    if (result.length > 20) result = [result substringToIndex:20];
    return result;
}

#pragma mark 主入口

+ (KKParsedBookEntry *)parseText:(NSString *)text categories:(NSArray<BKCModel *> *)categories referenceDate:(NSDate *)referenceDate {
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

    // 4. 备注
    entry.mark = [self markFrom:work];
    return entry;
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
