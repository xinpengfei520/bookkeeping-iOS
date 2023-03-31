//
//  备注 Model
//  MarkModel.h
//  bookkeeping
//
//  Created by PengfeiXin on 2022/7/22.
//  Copyright © 2022 kk. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

#pragma typeof
typedef void (^ErrorMsgBlock)(NSString *errorMsg);

@interface MarkModel : BaseModel<NSCoding, NSCopying>

@property (nonatomic, assign) NSInteger markId;
@property (nonatomic, strong) NSString *markName;
@property (nonatomic, assign) NSInteger frequency;
@property (nonatomic, assign) NSInteger categoryId;

+ (void)update:(BookDetailModel *)model errorMsg:(ErrorMsgBlock)errorMsgBlock;

@end

NS_ASSUME_NONNULL_END
