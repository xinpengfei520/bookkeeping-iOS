//
//  UserModel.h
//  imiss-ios-master
//
//  Created by zhongke on 2018/11/9.
//  Copyright © 2018年 kk. All rights reserved.
//

#import "BaseModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface UserModel : BaseModel

@property (nonatomic, assign) NSInteger Id;
@property (nonatomic, strong) NSString *icon;
@property (nonatomic, strong) NSString *account;
@property (nonatomic, strong) NSString *nickname;
@property (nonatomic, strong) NSString *token;
@property (nonatomic, assign) BOOL sex;
@property (nonatomic, assign) BOOL isPunch;
@property (nonatomic, strong) NSString *punchCount;
@property (nonatomic, assign) NSInteger faceId;

@end

NS_ASSUME_NONNULL_END
