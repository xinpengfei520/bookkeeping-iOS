//
//  PendingBookOpTests.m
//  bookkeepingTests
//
//  离线待办队列（PIN_BOOK_FAILED）的合并语义与旧格式兼容。
//  队列决定了弱网下增/改/删最终会不会正确落到服务端，合并规则错了会发出
//  自相矛盾的请求（例如给服务端没见过的临时 id 发 update），所以锁死。
//

#import <XCTest/XCTest.h>

#pragma mark - 宿主 App 符号重声明

typedef NS_ENUM(NSInteger, KKBookOpType) {
    KKBookOpTypeAdd    = 0,
    KKBookOpTypeUpdate = 1,
    KKBookOpTypeDelete = 2,
};

@interface BookDetailModel : NSObject
@property (nonatomic, assign) NSInteger bookId;
@property (nonatomic, assign) CGFloat price;
@property (nonatomic, copy  ) NSString *mark;
+ (NSNumber *)getBookId;
@end

@interface KKPendingBookOp : NSObject
@property (nonatomic, assign) KKBookOpType type;
@property (nonatomic, strong) BookDetailModel *model;
+ (instancetype)opWithType:(KKBookOpType)type model:(BookDetailModel *)model;
@end

@interface NSUserDefaults (KKPendingTest)
+ (void)setObject:(id)obj forKey:(NSString *)key;
+ (NSMutableArray<KKPendingBookOp *> *)getPendingBookOps;
+ (void)enqueuePendingAdd:(BookDetailModel *)model;
+ (void)enqueuePendingUpdate:(BookDetailModel *)model;
+ (void)enqueuePendingDelete:(BookDetailModel *)model;
+ (void)dequeuePendingBookOpForBookId:(NSInteger)bookId;
+ (void)clearPendingBookOps;
@end

static NSString * const kQueueKey = @"PIN_BOOK_FAILED";


@interface PendingBookOpTests : XCTestCase
@end

@implementation PendingBookOpTests

- (void)setUp {
    [NSUserDefaults clearPendingBookOps];
}

- (void)tearDown {
    [NSUserDefaults clearPendingBookOps];
}

- (BookDetailModel *)modelWithId:(NSInteger)bookId price:(CGFloat)price {
    BookDetailModel *m = [[BookDetailModel alloc] init];
    m.bookId = bookId;
    m.price = price;
    m.mark = @"测试";
    return m;
}

#pragma mark - 基本入队/出队

- (void)testEnqueueAndDequeue {
    [NSUserDefaults enqueuePendingAdd:[self modelWithId:-1 price:10]];
    [NSUserDefaults enqueuePendingDelete:[self modelWithId:2001 price:20]];

    NSArray<KKPendingBookOp *> *ops = [NSUserDefaults getPendingBookOps];
    XCTAssertEqual(ops.count, 2);
    XCTAssertEqual(ops[0].type, KKBookOpTypeAdd);
    XCTAssertEqual(ops[1].type, KKBookOpTypeDelete);

    [NSUserDefaults dequeuePendingBookOpForBookId:-1];
    ops = [NSUserDefaults getPendingBookOps];
    XCTAssertEqual(ops.count, 1);
    XCTAssertEqual(ops[0].model.bookId, 2001);
}

#pragma mark - 合并语义

// 排队新增 + 再修改 → 仍是新增（内容取最新）。
// 关键：临时 bookId 服务端还没见过，绝不能退化成 update 请求。
- (void)testAddThenUpdateStaysAdd {
    [NSUserDefaults enqueuePendingAdd:[self modelWithId:-1 price:10]];
    [NSUserDefaults enqueuePendingUpdate:[self modelWithId:-1 price:99]];

    NSArray<KKPendingBookOp *> *ops = [NSUserDefaults getPendingBookOps];
    XCTAssertEqual(ops.count, 1);
    XCTAssertEqual(ops[0].type, KKBookOpTypeAdd);
    XCTAssertEqualWithAccuracy(ops[0].model.price, 99, 0.001, @"内容应取最新");
}

// 排队新增 + 再删除 → 整条撤销（服务端从没见过它，不必发任何请求）
- (void)testAddThenDeleteCancelsOut {
    [NSUserDefaults enqueuePendingAdd:[self modelWithId:-1 price:10]];
    [NSUserDefaults enqueuePendingDelete:[self modelWithId:-1 price:10]];

    XCTAssertEqual([NSUserDefaults getPendingBookOps].count, 0);
}

// 排队修改 + 再修改 → 覆盖为最新
- (void)testUpdateThenUpdateOverwrites {
    [NSUserDefaults enqueuePendingUpdate:[self modelWithId:2001 price:10]];
    [NSUserDefaults enqueuePendingUpdate:[self modelWithId:2001 price:88]];

    NSArray<KKPendingBookOp *> *ops = [NSUserDefaults getPendingBookOps];
    XCTAssertEqual(ops.count, 1);
    XCTAssertEqual(ops[0].type, KKBookOpTypeUpdate);
    XCTAssertEqualWithAccuracy(ops[0].model.price, 88, 0.001);
}

// 排队修改 + 再删除 → 变为删除（改了又删，只需要发删除）
- (void)testUpdateThenDeleteBecomesDelete {
    [NSUserDefaults enqueuePendingUpdate:[self modelWithId:2001 price:10]];
    [NSUserDefaults enqueuePendingDelete:[self modelWithId:2001 price:10]];

    NSArray<KKPendingBookOp *> *ops = [NSUserDefaults getPendingBookOps];
    XCTAssertEqual(ops.count, 1);
    XCTAssertEqual(ops[0].type, KKBookOpTypeDelete);
}

// 不同 bookId 互不影响
- (void)testDifferentBookIdsDoNotMerge {
    [NSUserDefaults enqueuePendingAdd:[self modelWithId:-1 price:10]];
    [NSUserDefaults enqueuePendingAdd:[self modelWithId:-2 price:20]];
    [NSUserDefaults enqueuePendingUpdate:[self modelWithId:-1 price:11]];

    NSArray<KKPendingBookOp *> *ops = [NSUserDefaults getPendingBookOps];
    XCTAssertEqual(ops.count, 2);
}

#pragma mark - 旧格式兼容

// 1.0.16 及更早：队列里直接存 BookDetailModel 数组，应被解读为"待新增"
- (void)testLegacyQueueFormatReadsAsAdd {
    NSMutableArray *legacy = [NSMutableArray arrayWithObjects:
                              [self modelWithId:-1 price:10],
                              [self modelWithId:-2 price:20], nil];
    [NSUserDefaults setObject:legacy forKey:kQueueKey];

    NSArray<KKPendingBookOp *> *ops = [NSUserDefaults getPendingBookOps];
    XCTAssertEqual(ops.count, 2);
    XCTAssertEqual(ops[0].type, KKBookOpTypeAdd);
    XCTAssertEqual(ops[1].type, KKBookOpTypeAdd);
    XCTAssertEqual(ops[0].model.bookId, -1);
}

#pragma mark - 临时 id

// 临时 bookId 必须是负数：服务端 id 恒为正，两者共用主键空间时靠符号隔离
- (void)testTempBookIdIsNegativeAndUnique {
    NSInteger first = [[BookDetailModel getBookId] integerValue];
    NSInteger second = [[BookDetailModel getBookId] integerValue];
    XCTAssertLessThan(first, 0);
    XCTAssertLessThan(second, 0);
    XCTAssertNotEqual(first, second);
}

@end
