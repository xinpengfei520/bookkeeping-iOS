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
            @[KKLocalized(@"头像"), @"ID", KKLocalized(@"昵称"), KKLocalized(@"性别"), KKLocalized(@"手机号"), KKLocalized(@"邮箱")],
            @[KKLocalized(@"修改密码")],
            @[KKLocalized(@"删除账号")]
        ];
    });
    return infoTableData;
}

@end 