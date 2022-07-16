//
//  NSMutableArray+Extension.m
//  bookkeeping
//
//  Created by zhongke on 2019/1/15.
//  Copyright © 2019年 kk. All rights reserved.
//

#import "NSMutableArray+Extension.h"

@implementation NSMutableArray (Extension)

// 过滤数据
+ (NSMutableArray *)kk_filteredArrayUsingStringFormat:(NSString *)format array:(NSArray *)array {
    NSPredicate *pre = [NSPredicate predicateWithFormat:format];
    NSMutableArray *arrm = [NSMutableArray arrayWithArray:[array filteredArrayUsingPredicate:pre]];
    return arrm;
}

+ (NSMutableArray *)kk_filteredArrayUsingPredicate:(NSPredicate *)pre array:(NSArray *)array {
    NSMutableArray *arrm = [NSMutableArray arrayWithArray:[array filteredArrayUsingPredicate:pre]];
    return arrm;
}

@end
