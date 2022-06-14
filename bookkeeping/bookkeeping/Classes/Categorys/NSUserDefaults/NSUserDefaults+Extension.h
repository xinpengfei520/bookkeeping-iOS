/**
 * 存储管理
 * @author 郑业强 2019-01-12 创建文件
 */

#import <Foundation/Foundation.h>
#import "BookDetailModel.h"
#import "BookMonthModel.h"
#import "CategoryListModel.h"
#import "ACAListModel.h"


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
// 修改本地记账
+ (void)updateBookModel:(BookDetailModel *)model;
// 删除本地记账
+ (void)deleteBookModel:(BookDetailModel *)model;
// 添加分类
+ (void)insertCategoryModel:(BKCModel *)model is_income:(BOOL)is_income;
// 删除分类
+ (void)removeCategoryModel:(BKCModel *)model is_income:(BOOL)is_income;
// 获取分类
+ (NSMutableArray *)getCategoryModel;
// 获取分类 Model 列表
+ (NSMutableArray *) getCategoryModelList;
// // 获取分类 Model 通过 categoryId
+ (BKCModel *) getCategoryModel:(NSInteger)categoryId;
// 保存月记账列表
+ (void)saveMonthModelList:(NSInteger)year month:(NSInteger)month array:(NSMutableArray *)array;
// 获取月记账列表
+ (NSMutableArray<BookMonthModel *> *)getMonthModelList:(NSInteger)year month:(NSInteger)month;

@end

NS_ASSUME_NONNULL_END
