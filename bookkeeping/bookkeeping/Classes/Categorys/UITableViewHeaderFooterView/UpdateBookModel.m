//
//  UpdateBookModel.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/7/19.
//  Copyright © 2022 kk. All rights reserved.
//

#import "UpdateBookModel.h"

@implementation UpdateBookModel

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

- (instancetype)copyWithZone:(NSZone *)zone {
    UpdateBookModel *model = [[[self class] allocWithZone:zone] init];
    model.oldPrice = self.oldPrice;
    model.model = self.model;
    return model;
}

@end
