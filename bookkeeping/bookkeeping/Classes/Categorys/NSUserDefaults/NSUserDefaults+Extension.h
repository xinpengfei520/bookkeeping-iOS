/**
 * 存储管理
 * @author 郑业强 2019-01-12 创建文件
 */

#import <Foundation/Foundation.h>
#import "BookDetailModel.h"
#import "BookMonthModel.h"
#import "CategoryListModel.h"
#import "ACAListModel.h"
#import "MarkModel.h"
#import "KKPendingBookOp.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSUserDefaults (Extension)

// 取值
+ (id)objectForKey:(NSString *)key;
// 存值
+ (void)setObject:(id)obj forKey:(NSString *)key;
// 删除记账
+ (void)removeBookModel:(BookDetailModel *)model;
// 添加记账
+ (void)insertBookModel:(BookDetailModel *)model;
// 修改记账
+ (void)replaceBookModel:(BookDetailModel *)model;

// ============ 离线待办队列（PIN_BOOK_FAILED）============
// 网络不通导致失败的增/改/删先入队，网络恢复后由 HomeController 按序补发。
// 获取队列（自动兼容 1.0.16 及更早只存 BookDetailModel 的旧格式，按"新增"解读）
+ (NSMutableArray<KKPendingBookOp *> *)getPendingBookOps;
/// 入队，按 bookId 合并，避免同一条记录堆积互相矛盾的操作：
///   已排队新增 + 再改  → 仍是新增（内容取最新）
///   已排队新增 + 再删  → 整条移除（服务端从没见过它，等于没发生）
///   已排队修改 + 再改  → 覆盖为最新
///   已排队修改 + 再删  → 变为删除
+ (void)enqueuePendingBookOp:(KKPendingBookOp *)op;
+ (void)enqueuePendingAdd:(BookDetailModel *)model;
+ (void)enqueuePendingUpdate:(BookDetailModel *)model;
+ (void)enqueuePendingDelete:(BookDetailModel *)model;
// 出队（按 bookId）
+ (void)dequeuePendingBookOpForBookId:(NSInteger)bookId;
// 清空（退出登录 / 删除账号）
+ (void)clearPendingBookOps;
// 添加分类
+ (void)insertCategoryModel:(BKCModel *)model is_income:(BOOL)is_income;
// 删除分类
+ (void)removeCategoryModel:(BKCModel *)model is_income:(BOOL)is_income;
// 获取分类
+ (NSMutableArray *)getCategoryModel;
// 获取分类 Model 列表
+ (NSMutableArray *) getCategoryModelList;
// 获取分类 Model 通过 categoryId
+ (BKCModel *) getCategoryModel:(NSInteger)categoryId;
// 获取分类 Model 的 categoryId，通过 keyword
+ (NSInteger)getCategoryId:(NSString*)keyword;
// 保存所有记账列表
+ (void)saveAllBookList:(NSMutableArray *)array;
// 获取所有记账列表
+ (NSMutableArray<BookDetailModel *> *)getAllBookList;
// 保存所有备注列表
+ (void)saveAllMarkList:(NSMutableArray *)array;
// 获取所有备注列表
+ (NSMutableArray<MarkModel *> *)getAllMarkList;

@end

NS_ASSUME_NONNULL_END
