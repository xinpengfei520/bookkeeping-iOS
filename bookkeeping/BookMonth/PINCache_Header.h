//
//  PINCache_Header.h
//  bookkeeping
//
//  Created by 郑业强 on 2019/1/8.
//  Copyright © 2019年 kk. All rights reserved.
//

#ifndef PINCache_Header_h
#define PINCache_Header_h



#define PIN_FIRST_RUN               @"PIN_FIRST_RUN"                   // 第一次运行程序


#pragma mark - 类别
// 支出
#define PIN_CATE_SYS_HAS_PAY              @"PIN_CATE_SYS_HAS_PAY"              // 系统 - 添加的 - 支出
#define PIN_CATE_SYS_REMOVE_PAY           @"PIN_CATE_SYS_REMOVE_PAY"           // 系统 - 删除的 - 支出
#define PIN_CATE_CUS_HAS_PAY              @"PIN_CATE_CUS_HAS_PAY"              // 用户 - 添加的 - 支出
#define PIN_CATE_SYS_Has_PAY_SYNCED       @"PIN_CATE_SYS_Has_PAY_SYNCED"       // 系统 - 添加的 - 支出 - 未同步(同步后应该为空)
#define PIN_CATE_SYS_REMOVE_PAY_SYNCED    @"PIN_CATE_SYS_REMOVE_PAY_SYNCED"    // 系统 - 删除的 - 支出 - 未同步(同步后应该为空)
#define PIN_CATE_CUS_HAS_PAY_SYNCED       @"PIN_CATE_CUS_HAS_PAY_SYNCED"       // 用户 - 添加的 - 支出 - 未同步(同步后应该为空)
#define PIN_CATE_CUS_REMOVE_PAY_SYNCED    @"PIN_CATE_CUS_REMOVE_PAY_SYNCED"    // 用户 - 删除的 - 支出 - 未同步(同步后应该为空)

// 收入
#define PIN_CATE_SYS_HAS_INCOME              @"PIN_CATE_SYS_HAS_INCOME"              // 系统 - 添加的 - 收入
#define PIN_CATE_SYS_REMOVE_INCOME           @"PIN_CATE_SYS_REMOVE_INCOME"           // 系统 - 删除的 - 收入
#define PIN_CATE_CUS_HAS_INCOME              @"PIN_CATE_CUS_HAS_INCOME"              // 用户 - 添加的 - 收入
#define PIN_CATE_SYS_Has_INCOME_SYNCED       @"PIN_CATE_SYS_Has_INCOME_SYNCED"       // 系统 - 添加的 - 收入 - 未同步(同步后应该为空)
#define PIN_CATE_SYS_REMOVE_INCOME_SYNCED    @"PIN_CATE_SYS_REMOVE_INCOME_SYNCED"    // 系统 - 删除的 - 收入 - 未同步(同步后应该为空)
#define PIN_CATE_CUS_HAS_INCOME_SYNCED       @"PIN_CATE_CUS_HAS_INCOME_SYNCED"       // 用户 - 添加的 - 收入 - 未同步(同步后应该为空)
#define PIN_CATE_CUS_REMOVE_INCOME_SYNCED    @"PIN_CATE_CUS_REMOVE_INCOME_SYNCED"    // 用户 - 删除的 - 收入 - 未同步(同步后应该为空)

#pragma mark - 添加类别
#define PIN_ACA_CATE    @"PIN_ACA_CATE"    // 添加类别

#pragma mark - 记账
#define All_BOOK_LIST      @"All_BOOK_LIST"       // 所有记账
#define PIN_BOOK_FAILED    @"PIN_BOOK_FAILED"     // 记账失败列表(先保存到本地，等网络好的时候再同步)

#pragma mark - 个人设置
#define PIN_SETTING_FACE_ID           @"PIN_SETTING_FACE_ID"            // FaceID
#define PIN_TIMING                    @"PIN_TIMING"                     // 定时通知
#define PIN_DESENSITIZATION           @"PIN_DESENSITIZATION"            // 脱敏显示

#pragma mark - 认证 token
#define AUTHORIZATION_TOKEN           @"AUTHORIZATION_TOKEN"            // auth token

#endif
