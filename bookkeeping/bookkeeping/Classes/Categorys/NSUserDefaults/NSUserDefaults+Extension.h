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

// ============ 离线记账队列（PIN_BOOK_FAILED）============
// 网络不通导致保存失败的记账先入队，网络恢复后由 HomeController 重放到服务端。
// 获取队列
+ (NSMutableArray<BookDetailModel *> *)getFailedBookList;
// 入队（按 bookId 去重）
+ (void)enqueueFailedBookModel:(BookDetailModel *)model;
// 出队
+ (void)dequeueFailedBookModel:(BookDetailModel *)model;
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
// 保存月记账列表
+ (void)saveMonthModelList:(NSInteger)year month:(NSInteger)month array:(NSMutableArray *)array;
// 获取月记账列表
+ (NSMutableArray<BookMonthModel *> *)getMonthModelList:(NSInteger)year month:(NSInteger)month;

@end

NS_ASSUME_NONNULL_END
