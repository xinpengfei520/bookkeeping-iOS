/**
 * 个人信息页面数据源
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface InfoTableDataSource : NSObject

/// 获取个人信息页面的表格数据
+ (NSArray<NSArray<NSString *> *> *)getInfoTableData;

// 定义 section 索引常量，方便使用
typedef NS_ENUM(NSInteger, InfoTableSection) {
    InfoTableSectionBasic = 0,    // 基本信息
    InfoTableSectionPassword = 1,  // 修改密码
    InfoTableSectionDelete = 2     // 删除账号
};

@end

NS_ASSUME_NONNULL_END 