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

+ (void)update:(BookDetailModel *)model {
    NSMutableArray<MarkModel *> *markList = [NSUserDefaults getAllMarkList];
    MarkModel *findModel = nil;
    for (MarkModel *markModel in markList) {
        if (markModel.categoryId == model.categoryId && [markModel.markName isEqualToString:model.mark]) {
            markModel.frequency++;
            findModel = markModel;
            break;
        }
    }
    
    // 修改
    if (findModel) {
        NSMutableDictionary *param = [NSMutableDictionary dictionary];
        [param setValue:@(findModel.markId) forKey:@"markId"];
        [param setValue:@(findModel.frequency) forKey:@"frequency"];
        
        [AFNManager POST:updateMarkRequest params:param complete:^(APPResult *result) {
            if (result.status == HttpStatusSuccess && result.code == BIZ_SUCCESS) {
                [NSUserDefaults saveAllMarkList:markList];
            } else {
                NSLog(@"[MarkModel update()] -> msg1: %@",result.msg);
            }
        }];
    }else { // 新增
        NSMutableDictionary *param = [NSMutableDictionary dictionary];
        [param setValue:model.mark forKey:@"markName"];
        [param setValue:@(1) forKey:@"frequency"];
        [param setValue:@(model.categoryId) forKey:@"categoryId"];
        
        [AFNManager POST:saveMarkRequest params:param complete:^(APPResult *result) {
            if (result.status == HttpStatusSuccess && result.code == BIZ_SUCCESS) {
                NSDictionary *dic = [[NSDictionary alloc]initWithDictionary:result.data];
                NSNumber *markId = [dic objectForKey:@"markId"];
                
                MarkModel *saveModel = [[MarkModel alloc]init];
                saveModel.markId = [markId intValue];
                saveModel.markName = model.mark;
                saveModel.frequency = 1;
                saveModel.categoryId = model.categoryId;
                
                // 保存
                [markList addObject:saveModel];
                [NSUserDefaults saveAllMarkList:markList];
            } else {
                NSLog(@"[MarkModel update()] -> msg2: %@",result.msg);
            }
        }];
    }
}

@end
