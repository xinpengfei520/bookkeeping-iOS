//
//  common.h
//  bookkeeping
//
//  Created by 郑业强 on 2019/1/8.
//  Copyright © 2019年 kk. All rights reserved.
//

#ifndef common_h
#define common_h


// 第三方
// NotificationCenter framework 是废弃的 Today extension API，迁到
// WidgetKit 后不再使用。
#import <MJExtension/MJExtension.h>


// 分类
#import "UIFont+Extension.h"
#import "NSDate+Extension.h"
#import "NSString+Extension.h"
#import "NSObject+NSCoding.h"
#import "UIColor+HEX.h"
#import "NSUserDefaults+Extension.h"
#import "NSMutableArray+Extension.h"

// i18n
#import "KKI18n.h"
#define KKLocalized(key) [KKI18n stringForKey:(key)]

// 多币种（BookDetailModel 的展示辅助方法要用；纯计算，不含网络层）
#import "KKCurrency.h"


// model
#import "BaseModel.h"
#import "BookDetailModel.h"
#import "BookMonthModel.h"
#import "BookChartModel.h"
#import "ACAListModel.h"
#import "BKCIncomeModel.h"



#endif
