/**
 * 记账本地存储 —— SQLite
 *
 * 背景：All_BOOK_LIST 原先是把整个 BookDetailModel 数组用 NSKeyedArchiver
 * 整体序列化进 App Group NSUserDefaults —— 每记一笔都要全量重写一遍，
 * 复杂度 O(记录数)，几千条后每次记账都是一次全列表归档 + plist 落盘。
 *
 * 现改为 App Group 容器里的 SQLite 单表（book_detail，主键 bookId），
 * 单笔增删改为 O(log n)，批量导入走事务。首次打开时自动把 NSUserDefaults
 * 里的旧数据迁移进来并删除旧 blob，主 App / BookMonth widget 谁先访问谁迁移
 * （迁移幂等，INSERT OR REPLACE 按 bookId 去重）。
 *
 * 本类同时编进主 App 与 widget target：只依赖 Foundation + sqlite3 +
 * BookDetailModel，不要引入 UIKit / 网络层。
 * 调用方不要直接用本类 —— 继续走 NSUserDefaults+Extension 的
 * insertBookModel: / getAllBookList 等旧接口，它们的实现已换到这里。
 *
 * @author 2026-08-04 创建文件
 */

#import <Foundation/Foundation.h>
#import "BookDetailModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface KKBookStore : NSObject

/// App Group 容器里的共享库（book.sqlite），带旧数据迁移
+ (instancetype)shared;
/// 指定路径的库（单元测试 / 基准测试用），不做旧数据迁移
+ (instancetype)storeWithPath:(NSString *)path;

/// 全量读取（按写入顺序）
- (NSMutableArray<BookDetailModel *> *)allBooks;
/// 记录条数
- (NSInteger)count;
/// 单笔写入（INSERT OR REPLACE，按 bookId 去重，增改同一入口）
- (void)saveBook:(BookDetailModel *)model;
/// 批量写入（单事务）
- (void)saveBooks:(NSArray<BookDetailModel *> *)models;
/// 清空后整体替换（单事务；服务端全量同步用）
- (void)replaceAllBooks:(NSArray<BookDetailModel *> *)models;
/// 按 bookId 删除
- (void)removeBookId:(NSInteger)bookId;
/// 删除某个类别下的全部记账（删除类别时联动清理历史记录）
- (void)removeBooksWithCategoryId:(NSInteger)categoryId;
/// 清空（退出登录）
- (void)removeAllBooks;

@end

NS_ASSUME_NONNULL_END
