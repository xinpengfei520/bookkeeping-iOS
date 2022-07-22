//
//  备注 Model
//  MarkModel.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/7/22.
//  Copyright © 2022 kk. All rights reserved.
//

#import "MarkModel.h"

@implementation MarkModel

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
    MarkModel *model = [[[self class] allocWithZone:zone] init];
    model.markId = self.markId;
    model.markName = self.markName;
    model.frequency = self.frequency;
    model.categoryId = self.categoryId;
    return model;
}

@end
