/**
 * 记账本地存储 —— SQLite
 * 说明见 KKBookStore.h。线程模型：所有 SQL 都在内部串行队列上同步执行，
 * 对外接口线程安全；调用方基本都在主线程，单笔操作在毫秒内返回。
 */

#import "KKBookStore.h"
#import <sqlite3.h>

static NSString * const kAppGroupID = @"group.xpf.widget";
static NSString * const kDBFileName = @"book.sqlite";
// 旧存储（NSKeyedArchiver 归档进 App Group NSUserDefaults）的 key，
// 与 PINCache_Header.h 的 All_BOOK_LIST 宏一致；迁移完成后该 key 被删除。
static NSString * const kLegacyKey = @"All_BOOK_LIST";

@interface KKBookStore ()

@property (nonatomic, assign) sqlite3 *db;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation KKBookStore

#pragma mark - 初始化

+ (instancetype)shared {
    static KKBookStore *_shared;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSURL *container = [[NSFileManager defaultManager]
            containerURLForSecurityApplicationGroupIdentifier:kAppGroupID];
        NSString *path = [container.path stringByAppendingPathComponent:kDBFileName];
        _shared = [[KKBookStore alloc] initWithPath:path];
        [_shared migrateFromLegacyDefaultsIfNeeded];
    });
    return _shared;
}

+ (instancetype)storeWithPath:(NSString *)path {
    return [[KKBookStore alloc] initWithPath:path];
}

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        _queue = dispatch_queue_create("com.xpf.record.bookstore", DISPATCH_QUEUE_SERIAL);
        dispatch_sync(_queue, ^{
            if (sqlite3_open(path.UTF8String, &self->_db) != SQLITE_OK) {
                KKLog(@"[KKBookStore] open failed: %s", sqlite3_errmsg(self->_db));
                sqlite3_close(self->_db);
                self->_db = NULL;
                return;
            }
            // WAL：写不阻塞读，且主 App / widget 跨进程并发访问更稳
            sqlite3_exec(self->_db, "PRAGMA journal_mode=WAL;", NULL, NULL, NULL);
            const char *ddl =
                "CREATE TABLE IF NOT EXISTS book_detail ("
                "  book_id        INTEGER PRIMARY KEY,"
                "  category_id    INTEGER NOT NULL DEFAULT 0,"
                "  price          REAL    NOT NULL DEFAULT 0,"
                "  year           INTEGER NOT NULL DEFAULT 0,"
                "  month          INTEGER NOT NULL DEFAULT 0,"
                "  day            INTEGER NOT NULL DEFAULT 0,"
                "  mark           TEXT,"
                "  currency       TEXT,"          // 多币种三字段，人民币记录为 NULL
                "  original_price REAL,"
                "  exchange_rate  REAL"
                ");"
                "CREATE INDEX IF NOT EXISTS idx_book_ym ON book_detail(year, month);";
            char *err = NULL;
            if (sqlite3_exec(self->_db, ddl, NULL, NULL, &err) != SQLITE_OK) {
                KKLog(@"[KKBookStore] create table failed: %s", err ?: "?");
                sqlite3_free(err);
            }
        });
    }
    return self;
}

- (void)dealloc {
    if (_db) {
        sqlite3_close(_db);
    }
}

#pragma mark - 旧数据迁移

// 首次打开：SQLite 为空且 NSUserDefaults 里还有旧归档 → 整体导入后删除旧 blob。
// 主 App 与 widget 都会走到这里，谁先谁迁；OR REPLACE 保证并发迁移也幂等。
- (void)migrateFromLegacyDefaultsIfNeeded {
    if ([self count] > 0) {
        return;
    }
    NSUserDefaults *sharedData = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupID];
    NSData *blob = [sharedData objectForKey:kLegacyKey];
    if (![blob isKindOfClass:[NSData class]] || blob.length == 0) {
        return;
    }
    // 旧格式：NSKeyedArchiver(requiresSecureCoding=NO) 归档的 NSMutableArray<BookDetailModel *>
    NSError *error = nil;
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:blob error:&error];
    unarchiver.requiresSecureCoding = NO;
    id list = [unarchiver decodeTopLevelObjectForKey:NSKeyedArchiveRootObjectKey error:&error];
    if (![list isKindOfClass:[NSArray class]]) {
        KKLog(@"[KKBookStore] legacy unarchive failed: %@", error);
        return;
    }
    [self saveBooks:list];
    // 导入成功才删旧数据，中途失败下次还能重试
    if ([self count] >= [(NSArray *)list count]) {
        [sharedData removeObjectForKey:kLegacyKey];
        KKLog(@"[KKBookStore] migrated %ld legacy records", (long)[(NSArray *)list count]);
    }
}

#pragma mark - 读

- (NSMutableArray<BookDetailModel *> *)allBooks {
    NSMutableArray *result = [NSMutableArray array];
    dispatch_sync(self.queue, ^{
        if (self.db == NULL) return;
        sqlite3_stmt *stmt = NULL;
        const char *sql = "SELECT book_id, category_id, price, year, month, day,"
                          " mark, currency, original_price, exchange_rate"
                          " FROM book_detail ORDER BY rowid;";
        if (sqlite3_prepare_v2(self.db, sql, -1, &stmt, NULL) != SQLITE_OK) {
            return;
        }
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            BookDetailModel *m = [[BookDetailModel alloc] init];
            m.bookId     = sqlite3_column_int64(stmt, 0);
            m.categoryId = sqlite3_column_int64(stmt, 1);
            m.price      = sqlite3_column_double(stmt, 2);
            m.year       = sqlite3_column_int64(stmt, 3);
            m.month      = sqlite3_column_int64(stmt, 4);
            m.day        = sqlite3_column_int64(stmt, 5);
            const char *mark = (const char *)sqlite3_column_text(stmt, 6);
            m.mark = mark ? [NSString stringWithUTF8String:mark] : @"";
            const char *currency = (const char *)sqlite3_column_text(stmt, 7);
            if (currency) {
                m.currency      = [NSString stringWithUTF8String:currency];
                m.originalPrice = sqlite3_column_double(stmt, 8);
                m.exchangeRate  = sqlite3_column_double(stmt, 9);
            }
            [result addObject:m];
        }
        sqlite3_finalize(stmt);
    });
    return result;
}

- (NSInteger)count {
    __block NSInteger n = 0;
    dispatch_sync(self.queue, ^{
        if (self.db == NULL) return;
        sqlite3_stmt *stmt = NULL;
        if (sqlite3_prepare_v2(self.db, "SELECT COUNT(*) FROM book_detail;", -1, &stmt, NULL) == SQLITE_OK) {
            if (sqlite3_step(stmt) == SQLITE_ROW) {
                n = sqlite3_column_int64(stmt, 0);
            }
        }
        sqlite3_finalize(stmt);
    });
    return n;
}

#pragma mark - 写

// 在当前队列上下文里绑定并执行一条 upsert（调用方负责在 self.queue 上）
- (void)p_bindAndSave:(BookDetailModel *)model stmt:(sqlite3_stmt *)stmt {
    sqlite3_bind_int64(stmt, 1, model.bookId);
    sqlite3_bind_int64(stmt, 2, model.categoryId);
    sqlite3_bind_double(stmt, 3, model.price);
    sqlite3_bind_int64(stmt, 4, model.year);
    sqlite3_bind_int64(stmt, 5, model.month);
    sqlite3_bind_int64(stmt, 6, model.day);
    if (model.mark.length) {
        sqlite3_bind_text(stmt, 7, model.mark.UTF8String, -1, SQLITE_TRANSIENT);
    } else {
        sqlite3_bind_null(stmt, 7);
    }
    // 多币种三字段要么全有要么全无（见对接文档）；人民币记录存 NULL
    if ([model isForeignCurrency]) {
        sqlite3_bind_text(stmt, 8, model.currency.UTF8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_double(stmt, 9, model.originalPrice);
        sqlite3_bind_double(stmt, 10, model.exchangeRate);
    } else {
        sqlite3_bind_null(stmt, 8);
        sqlite3_bind_null(stmt, 9);
        sqlite3_bind_null(stmt, 10);
    }
    if (sqlite3_step(stmt) != SQLITE_DONE) {
        KKLog(@"[KKBookStore] save failed: %s", sqlite3_errmsg(self.db));
    }
    sqlite3_reset(stmt);
}

static const char *kUpsertSQL =
    "INSERT OR REPLACE INTO book_detail"
    " (book_id, category_id, price, year, month, day, mark, currency, original_price, exchange_rate)"
    " VALUES (?,?,?,?,?,?,?,?,?,?);";

- (void)saveBook:(BookDetailModel *)model {
    if (model == nil) return;
    dispatch_sync(self.queue, ^{
        if (self.db == NULL) return;
        sqlite3_stmt *stmt = NULL;
        if (sqlite3_prepare_v2(self.db, kUpsertSQL, -1, &stmt, NULL) != SQLITE_OK) return;
        [self p_bindAndSave:model stmt:stmt];
        sqlite3_finalize(stmt);
    });
}

- (void)saveBooks:(NSArray<BookDetailModel *> *)models {
    if (models.count == 0) return;
    dispatch_sync(self.queue, ^{
        if (self.db == NULL) return;
        sqlite3_exec(self.db, "BEGIN TRANSACTION;", NULL, NULL, NULL);
        sqlite3_stmt *stmt = NULL;
        if (sqlite3_prepare_v2(self.db, kUpsertSQL, -1, &stmt, NULL) == SQLITE_OK) {
            for (BookDetailModel *m in models) {
                if ([m isKindOfClass:[BookDetailModel class]]) {
                    [self p_bindAndSave:m stmt:stmt];
                }
            }
            sqlite3_finalize(stmt);
        }
        sqlite3_exec(self.db, "COMMIT;", NULL, NULL, NULL);
    });
}

- (void)replaceAllBooks:(NSArray<BookDetailModel *> *)models {
    dispatch_sync(self.queue, ^{
        if (self.db == NULL) return;
        sqlite3_exec(self.db, "BEGIN TRANSACTION;", NULL, NULL, NULL);
        sqlite3_exec(self.db, "DELETE FROM book_detail;", NULL, NULL, NULL);
        sqlite3_stmt *stmt = NULL;
        if (sqlite3_prepare_v2(self.db, kUpsertSQL, -1, &stmt, NULL) == SQLITE_OK) {
            for (BookDetailModel *m in models) {
                if ([m isKindOfClass:[BookDetailModel class]]) {
                    [self p_bindAndSave:m stmt:stmt];
                }
            }
            sqlite3_finalize(stmt);
        }
        sqlite3_exec(self.db, "COMMIT;", NULL, NULL, NULL);
    });
}

- (void)removeBookId:(NSInteger)bookId {
    dispatch_sync(self.queue, ^{
        if (self.db == NULL) return;
        sqlite3_stmt *stmt = NULL;
        if (sqlite3_prepare_v2(self.db, "DELETE FROM book_detail WHERE book_id = ?;", -1, &stmt, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(stmt, 1, bookId);
            sqlite3_step(stmt);
        }
        sqlite3_finalize(stmt);
    });
}

- (void)removeBooksWithCategoryId:(NSInteger)categoryId {
    dispatch_sync(self.queue, ^{
        if (self.db == NULL) return;
        sqlite3_stmt *stmt = NULL;
        if (sqlite3_prepare_v2(self.db, "DELETE FROM book_detail WHERE category_id = ?;", -1, &stmt, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(stmt, 1, categoryId);
            sqlite3_step(stmt);
        }
        sqlite3_finalize(stmt);
    });
}

- (void)removeAllBooks {
    dispatch_sync(self.queue, ^{
        if (self.db == NULL) return;
        sqlite3_exec(self.db, "DELETE FROM book_detail;", NULL, NULL, NULL);
    });
}

@end
