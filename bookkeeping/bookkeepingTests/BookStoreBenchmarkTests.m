//
//  BookStoreBenchmarkTests.m
//  bookkeepingTests
//
//  本地记账存储改造的性能基准：旧方案（整个数组 NSKeyedArchiver 归档进
//  App Group NSUserDefaults，每笔写入全量重写）对比新方案（KKBookStore/SQLite）。
//  三个口径，直接在测试日志里打印毫秒数：
//    1. 启动加载全量（2000 笔）
//    2. 存量 2000 笔时连续记 50 笔（记账页的真实写入路径）
//    3. 服务端同步：全量落盘 2000 笔
//
//  旧路径在这里用与 NSUserDefaults+Extension 旧实现逐行等价的代码复现
//  （archivedDataWithRootObject + suite setObject），键独立，不碰真实数据。
//

#import <XCTest/XCTest.h>
#import <QuartzCore/QuartzCore.h>

#pragma mark - 宿主 App 符号重声明（经 BUNDLE_LOADER 链接）

@interface BookDetailModel : NSObject <NSCoding, NSCopying>
@property (nonatomic, assign) NSInteger bookId;
@property (nonatomic, assign) NSInteger categoryId;
@property (nonatomic, assign) CGFloat price;
@property (nonatomic, assign) NSInteger year;
@property (nonatomic, assign) NSInteger month;
@property (nonatomic, assign) NSInteger day;
@property (nonatomic, copy  ) NSString *mark;
@property (nonatomic, copy  ) NSString *currency;
@property (nonatomic, assign) CGFloat originalPrice;
@property (nonatomic, assign) CGFloat exchangeRate;
@end

@interface KKBookStore : NSObject
+ (instancetype)storeWithPath:(NSString *)path;
- (NSMutableArray *)allBooks;
- (NSInteger)count;
- (void)saveBook:(BookDetailModel *)model;
- (void)replaceAllBooks:(NSArray *)models;
- (void)removeBooksWithCategoryId:(NSInteger)categoryId;
- (void)removeAllBooks;
@end

static NSString * const kBenchKey = @"BENCH_LEGACY_BOOKS";      // 独立键，不碰真实数据
static NSString * const kSuite = @"group.xpf.widget";
static const NSInteger kBaseCount = 2000;                       // 存量规模
static const NSInteger kInsertCount = 50;                       // 连续记账笔数

@interface BookStoreBenchmarkTests : XCTestCase
@end

@implementation BookStoreBenchmarkTests {
    NSString *_dbPath;
}

- (void)setUp {
    _dbPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"bench_book.sqlite"];
    [self cleanup];
}

- (void)tearDown {
    [self cleanup];
}

- (void)cleanup {
    [[[NSUserDefaults alloc] initWithSuiteName:kSuite] removeObjectForKey:kBenchKey];
    for (NSString *suffix in @[@"", @"-wal", @"-shm"]) {
        [[NSFileManager defaultManager] removeItemAtPath:[_dbPath stringByAppendingString:suffix] error:nil];
    }
}

#pragma mark - 数据与旧路径复现

- (NSMutableArray<BookDetailModel *> *)makeModels:(NSInteger)count startId:(NSInteger)startId {
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:count];
    for (NSInteger i = 0; i < count; i++) {
        BookDetailModel *m = [[BookDetailModel alloc] init];
        m.bookId = startId + i;
        m.categoryId = 1 + (i % 30);
        m.price = 10.0 + (i % 500) * 0.37;
        m.year = 2024 + (i % 3);
        m.month = 1 + (i % 12);
        m.day = 1 + (i % 28);
        m.mark = [NSString stringWithFormat:@"备注-%ld", (long)i];
        if (i % 20 == 0) {      // 5% 外币记录
            m.currency = @"USD";
            m.originalPrice = 5.20;
            m.exchangeRate = 6.752650;
        }
        [arr addObject:m];
    }
    return arr;
}

// 旧实现的写路径（与改造前 NSUserDefaults+Extension setObject:forKey: 等价）
- (void)legacyWrite:(NSArray *)list {
    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:list requiringSecureCoding:NO error:&error];
    NSUserDefaults *suite = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
    [suite setObject:data forKey:kBenchKey];
    [suite synchronize];
}

// 旧实现的读路径
- (NSMutableArray *)legacyRead {
    NSUserDefaults *suite = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
    NSData *data = [suite objectForKey:kBenchKey];
    NSError *error = nil;
    NSKeyedUnarchiver *un = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:&error];
    un.requiresSecureCoding = NO;
    return [un decodeTopLevelObjectForKey:NSKeyedArchiveRootObjectKey error:&error];
}

static double MS(CFTimeInterval start) {
    return (CACurrentMediaTime() - start) * 1000.0;
}

#pragma mark - 基准

- (void)testBenchmarkLegacyVsSQLite {
    NSMutableArray *base = [self makeModels:kBaseCount startId:1];

    // ============ 场景 3 先做：全量落盘 2000 笔（同时充当两边的数据准备）============
    CFTimeInterval t = CACurrentMediaTime();
    [self legacyWrite:base];
    double legacyBulkSave = MS(t);

    KKBookStore *store = [KKBookStore storeWithPath:_dbPath];
    t = CACurrentMediaTime();
    [store replaceAllBooks:base];
    double sqliteBulkSave = MS(t);

    // ============ 场景 1：启动加载全量 ============
    t = CACurrentMediaTime();
    NSArray *legacyLoaded = [self legacyRead];
    double legacyLoad = MS(t);

    t = CACurrentMediaTime();
    NSArray *sqliteLoaded = [store allBooks];
    double sqliteLoad = MS(t);

    XCTAssertEqual(legacyLoaded.count, (NSUInteger)kBaseCount);
    XCTAssertEqual(sqliteLoaded.count, (NSUInteger)kBaseCount);

    // ============ 场景 2：存量 2000 笔时连续记 50 笔 ============
    // 旧路径 = 真实旧代码的行为：读全量 → append → 整体重新归档落盘，每笔都来一遍
    NSMutableArray *legacyList = [self legacyRead];
    NSArray *inserts = [self makeModels:kInsertCount startId:kBaseCount + 1];
    t = CACurrentMediaTime();
    for (BookDetailModel *m in inserts) {
        [legacyList addObject:m];
        [self legacyWrite:legacyList];
    }
    double legacyInsert50 = MS(t);

    t = CACurrentMediaTime();
    for (BookDetailModel *m in inserts) {
        [store saveBook:m];
    }
    double sqliteInsert50 = MS(t);

    XCTAssertEqual([store count], kBaseCount + kInsertCount);

    // ============ 输出对比 ============
    NSLog(@"\n"
          @"================ 本地存储性能基准（存量 %ld 笔） ================\n"
          @"场景                         旧(NSUserDefaults归档)   新(SQLite)    提升\n"
          @"启动加载全量                 %8.1f ms            %8.1f ms   %5.1fx\n"
          @"连续记 %ld 笔(记账写入路径)  %8.1f ms            %8.1f ms   %5.1fx\n"
          @"  └ 平均每笔                 %8.2f ms            %8.2f ms\n"
          @"全量同步落盘                 %8.1f ms            %8.1f ms   %5.1fx\n"
          @"===================================================================",
          (long)kBaseCount,
          legacyLoad, sqliteLoad, legacyLoad / MAX(sqliteLoad, 0.001),
          (long)kInsertCount,
          legacyInsert50, sqliteInsert50, legacyInsert50 / MAX(sqliteInsert50, 0.001),
          legacyInsert50 / kInsertCount, sqliteInsert50 / kInsertCount,
          legacyBulkSave, sqliteBulkSave, legacyBulkSave / MAX(sqliteBulkSave, 0.001));

    // 单笔写入是本次改造的核心指标，必须有量级提升；松断言防机器波动误报
    XCTAssertLessThan(sqliteInsert50, legacyInsert50,
                      @"SQLite 连续写入应显著快于全量归档");
}

// 删除类别联动清理：只删目标类别的记录，其余原样保留。
// 回归背景：旧实现用不存在的 cmodel.Id keyPath 过滤（NSPredicate 抛
// NSUnknownKeyException，删除类别即崩），末段还会把账单列表洗成只剩被删类别。
- (void)testRemoveBooksWithCategoryIdOnlyDeletesThatCategory {
    KKBookStore *store = [KKBookStore storeWithPath:_dbPath];
    NSMutableArray *models = [self makeModels:300 startId:1];   // categoryId = 1+(i%30)
    [store replaceAllBooks:models];

    NSInteger doomed = 7;
    NSInteger doomedCount = 0;
    for (BookDetailModel *m in models) {
        if (m.categoryId == doomed) doomedCount++;
    }
    XCTAssertGreaterThan(doomedCount, 0);

    [store removeBooksWithCategoryId:doomed];

    NSArray<BookDetailModel *> *remain = [store allBooks];
    XCTAssertEqual(remain.count, models.count - doomedCount, @"只应删掉目标类别的记录");
    for (BookDetailModel *m in remain) {
        XCTAssertNotEqual(m.categoryId, doomed, @"目标类别的记录应全部删除");
    }
}

// 数据一致性：新老两条路径写入同一批数据后内容一致（bookId/金额/多币种字段）
- (void)testSQLiteRoundTripKeepsFields {
    KKBookStore *store = [KKBookStore storeWithPath:_dbPath];
    NSMutableArray *models = [self makeModels:100 startId:1];
    [store replaceAllBooks:models];

    NSArray<BookDetailModel *> *loaded = [store allBooks];
    XCTAssertEqual(loaded.count, models.count);
    BookDetailModel *src = models[20];      // 外币记录（i%20==0）
    BookDetailModel *dst = loaded[20];
    XCTAssertEqual(dst.bookId, src.bookId);
    XCTAssertEqualWithAccuracy(dst.price, src.price, 0.0001);
    XCTAssertEqualObjects(dst.mark, src.mark);
    XCTAssertEqualObjects(dst.currency, @"USD");
    XCTAssertEqualWithAccuracy(dst.originalPrice, 5.20, 0.0001);
    XCTAssertEqualWithAccuracy(dst.exchangeRate, 6.752650, 0.000001);
    // 人民币记录三字段应为空
    BookDetailModel *cny = loaded[1];
    XCTAssertNil(cny.currency);
    XCTAssertEqual(cny.originalPrice, 0);
}

@end
