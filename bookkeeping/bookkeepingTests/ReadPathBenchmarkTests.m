//
//  ReadPathBenchmarkTests.m
//  bookkeepingTests
//
//  读路径性能改造的基准对比（2026-08-05）。四个口径，旧路径在测试里逐行复刻：
//    1. 日期解析 2000 次：每次新建 NSDateFormatter（旧） vs 进程级缓存（新，dateWithYMD:）
//    2. 月度筛选：全量加载 + NSPredicate 内存过滤（旧） vs SQL WHERE 索引直查（新）
//    3. 年账单聚合：26 趟谓词 + @sum KVC（旧） vs 单趟分桶（新）
//    4. 图表日期范围：@min.date/@max.date KVC（触发逐条 formatter 创建，旧）
//       vs 单趟 dateNumber 整数比较（新）
//

#import <XCTest/XCTest.h>
#import <QuartzCore/QuartzCore.h>

#pragma mark - 宿主 App 符号重声明

@interface BookDetailModel : NSObject
@property (nonatomic, assign) NSInteger bookId;
@property (nonatomic, assign) NSInteger categoryId;
@property (nonatomic, assign) CGFloat price;
@property (nonatomic, assign) NSInteger year;
@property (nonatomic, assign) NSInteger month;
@property (nonatomic, assign) NSInteger day;
@property (nonatomic, copy  ) NSString *mark;
@property (nonatomic, readonly) NSInteger dateNumber;
@property (nonatomic, readonly) NSDate *date;
@end

@interface KKBookStore : NSObject
+ (instancetype)storeWithPath:(NSString *)path;
- (NSMutableArray<BookDetailModel *> *)allBooks;
- (NSMutableArray<BookDetailModel *> *)booksWithYear:(NSInteger)year month:(NSInteger)month;
- (void)replaceAllBooks:(NSArray *)models;
@end

@interface NSDate (KKBenchTest)
+ (NSDate *)dateWithYMD:(NSString *)dateStr;
@end

static const NSInteger kCount = 2000;

static double MS(CFTimeInterval start) {
    return (CACurrentMediaTime() - start) * 1000.0;
}

@interface ReadPathBenchmarkTests : XCTestCase
@end

@implementation ReadPathBenchmarkTests {
    NSString *_dbPath;
    NSMutableArray<BookDetailModel *> *_models;
}

- (void)setUp {
    _dbPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"bench_read.sqlite"];
    [self cleanup];
    _models = [NSMutableArray arrayWithCapacity:kCount];
    for (NSInteger i = 0; i < kCount; i++) {
        BookDetailModel *m = [[BookDetailModel alloc] init];
        m.bookId = i + 1;
        m.categoryId = 1 + (i % 40);            // 1~32 支出，33~40 收入
        m.price = 10.0 + (i % 500) * 0.37;
        // i%3 与 (i/3)%12 相互独立，保证 (year, month) 全组合都有数据
        // （若都用 i 取模，模数相关会导致某些组合恒为空）
        m.year = 2024 + (i % 3);                // 三年数据
        m.month = 1 + ((i / 3) % 12);
        m.day = 1 + ((i / 36) % 28);
        m.mark = [NSString stringWithFormat:@"备注-%ld", (long)i];
        [_models addObject:m];
    }
}

- (void)tearDown {
    [self cleanup];
}

- (void)cleanup {
    for (NSString *suffix in @[@"", @"-wal", @"-shm"]) {
        [[NSFileManager defaultManager] removeItemAtPath:[_dbPath stringByAppendingString:suffix] error:nil];
    }
}

- (void)testBenchmarkReadPaths {
    // ================= 1. 日期解析：新建 formatter vs 缓存 =================
    CFTimeInterval t = CACurrentMediaTime();
    for (NSInteger i = 0; i < kCount; i++) {
        // 旧路径逐行复刻：每次解析都新建 formatter + calendar（原 createDateWithFora:）
        NSDateFormatter *fora = [[NSDateFormatter alloc] init];
        fora.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        fora.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        [fora setDateFormat:@"yyyy-MM-dd"];
        [fora setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
        (void)[fora dateFromString:@"2026-08-05"];
    }
    double legacyParse = MS(t);

    (void)[NSDate dateWithYMD:@"2026-01-01"];   // 预热缓存
    t = CACurrentMediaTime();
    for (NSInteger i = 0; i < kCount; i++) {
        (void)[NSDate dateWithYMD:@"2026-08-05"];
    }
    double cachedParse = MS(t);

    // ================= 2. 月度筛选：谓词内存过滤 vs SQL 索引 =================
    KKBookStore *store = [KKBookStore storeWithPath:_dbPath];
    [store replaceAllBooks:_models];

    t = CACurrentMediaTime();
    NSArray *legacyMonth = nil;
    for (NSInteger i = 0; i < 10; i++) {        // 模拟一次操作触发的多次刷新
        NSArray *all = [store allBooks];
        NSPredicate *pre = [NSPredicate predicateWithFormat:@"year == 2025 AND month == 6"];
        legacyMonth = [all filteredArrayUsingPredicate:pre];
    }
    double legacyMonthFilter = MS(t) / 10;

    t = CACurrentMediaTime();
    NSArray *sqlMonth = nil;
    for (NSInteger i = 0; i < 10; i++) {
        sqlMonth = [store booksWithYear:2025 month:6];
    }
    double sqlMonthFilter = MS(t) / 10;
    XCTAssertEqual(legacyMonth.count, sqlMonth.count, @"两条路径的月度结果应一致");
    XCTAssertGreaterThan(sqlMonth.count, 0);

    // ================= 3. 年账单聚合：26 趟谓词+KVC vs 单趟分桶 =================
    t = CACurrentMediaTime();
    CGFloat legacyIncomeTotal = 0;
    {
        NSArray *bookArr = _models;
        NSArray *incomeArr = [bookArr filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"year == 2025 AND categoryId >= 33"]];
        NSArray *payArr = [bookArr filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"year == 2025 AND categoryId <= 32"]];
        legacyIncomeTotal = [[incomeArr valueForKeyPath:@"@sum.price"] doubleValue];
        (void)[[payArr valueForKeyPath:@"@sum.price"] doubleValue];
        for (NSInteger i = 1; i <= 12; i++) {
            NSArray *incomeModels = [bookArr filteredArrayUsingPredicate:
                [NSPredicate predicateWithFormat:@"year == 2025 AND month == %ld AND categoryId >= 33", (long)i]];
            NSArray *payModels = [bookArr filteredArrayUsingPredicate:
                [NSPredicate predicateWithFormat:@"year == 2025 AND month == %ld AND categoryId <= 32", (long)i]];
            (void)[[incomeModels valueForKeyPath:@"@sum.price"] doubleValue];
            (void)[[payModels valueForKeyPath:@"@sum.price"] doubleValue];
        }
    }
    double legacyBill = MS(t);

    t = CACurrentMediaTime();
    CGFloat newIncomeTotal = 0;
    {
        CGFloat incomeByMonth[13] = {0}, payByMonth[13] = {0};
        CGFloat incomeTotal = 0, payTotal = 0;
        for (BookDetailModel *m in _models) {
            if (m.year != 2025 || m.month < 1 || m.month > 12) continue;
            if (m.categoryId >= 33) { incomeByMonth[m.month] += m.price; incomeTotal += m.price; }
            else { payByMonth[m.month] += m.price; payTotal += m.price; }
        }
        (void)incomeByMonth; (void)payByMonth; (void)payTotal;
        newIncomeTotal = incomeTotal;
    }
    double newBill = MS(t);
    XCTAssertEqualWithAccuracy(legacyIncomeTotal, newIncomeTotal, 0.01, @"聚合结果应一致");

    // ================= 4. 日期范围：@min.date KVC vs 单趟整数比较 =================
    t = CACurrentMediaTime();
    NSDate *legacyMin = [_models valueForKeyPath:@"@min.date"];
    NSDate *legacyMax = [_models valueForKeyPath:@"@max.date"];
    double legacyRange = MS(t);
    XCTAssertNotNil(legacyMin); XCTAssertNotNil(legacyMax);

    t = CACurrentMediaTime();
    BookDetailModel *minModel = nil, *maxModel = nil;
    NSInteger minN = NSIntegerMax, maxN = NSIntegerMin;
    for (BookDetailModel *m in _models) {
        NSInteger n = m.dateNumber;
        if (n < minN) { minN = n; minModel = m; }
        if (n > maxN) { maxN = n; maxModel = m; }
    }
    double newRange = MS(t);
    XCTAssertNotNil(minModel); XCTAssertNotNil(maxModel);

    // ================= 输出 =================
    NSLog(@"\n"
          @"================ 读路径性能基准（%ld 条存量） ================\n"
          @"场景                          旧实现          新实现        提升\n"
          @"日期解析 ×2000            %8.1f ms    %8.1f ms   %6.1fx\n"
          @"首页月度筛选(单次)        %8.2f ms    %8.2f ms   %6.1fx\n"
          @"年账单聚合(26趟→单趟)     %8.2f ms    %8.2f ms   %6.1fx\n"
          @"图表日期范围(min/max)     %8.1f ms    %8.2f ms   %6.1fx\n"
          @"==============================================================",
          (long)kCount,
          legacyParse, cachedParse, legacyParse / MAX(cachedParse, 0.001),
          legacyMonthFilter, sqlMonthFilter, legacyMonthFilter / MAX(sqlMonthFilter, 0.001),
          legacyBill, newBill, legacyBill / MAX(newBill, 0.001),
          legacyRange, newRange, legacyRange / MAX(newRange, 0.001));

    XCTAssertLessThan(cachedParse, legacyParse);
    XCTAssertLessThan(newBill, legacyBill);
    XCTAssertLessThan(newRange, legacyRange);
}

@end
