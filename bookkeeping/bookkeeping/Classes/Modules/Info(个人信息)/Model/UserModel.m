//
//  UserModel.m
//  imiss-ios-master
//
//  Created by zhongke on 2018/11/9.
//  Copyright © 2018年 kk. All rights reserved.
//

#import "UserModel.h"

@implementation UserModel

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    self = [NSObject decodeClass:self decoder:aDecoder];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [NSObject encodeClass:self encoder:aCoder];
}

+ (void)load {
    // 后台返回的 json 里面含有 id、等 OC 关键字的时候，需要进行 model 属性的 key 的替换
//    [UserModel mj_setupReplacedKeyFromPropertyName:^NSDictionary *{
//        return @{
//            @"Id": @"id"
//        };
//    }];
}

@end
