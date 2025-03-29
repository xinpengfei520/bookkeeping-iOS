/**
 * 个人信息页面数据源
 */

#import "InfoTableDataSource.h"

@implementation InfoTableDataSource

+ (NSArray<NSArray<NSString *> *> *)getInfoTableData {
    static NSArray<NSArray<NSString *> *> *infoTableData = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        infoTableData = @[
            @[@"头像", @"ID", @"昵称", @"性别", @"手机号", @"邮箱"],
            @[@"修改密码"],
            @[@"删除账号"]
        ];
    });
    return infoTableData;
}

@end 