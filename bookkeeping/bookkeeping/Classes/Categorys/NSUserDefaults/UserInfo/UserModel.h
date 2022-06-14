//
//  UserModel.h
//  imiss-ios-master
//
//  Created by zhongke on 2018/11/9.
//  Copyright © 2018年 kk. All rights reserved.
//

#import "BaseModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface UserModel : BaseModel<NSCoding>

@property (nonatomic, assign) NSString *userId;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *userPhone;
@property (nonatomic, strong) NSString *userAvatar;
@property (nonatomic, strong) NSString *registerTime;
@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSString *bookDays;
@property (nonatomic, strong) NSString *bookCounts;
@property (nonatomic, assign) NSInteger faceId;

@end

NS_ASSUME_NONNULL_END
