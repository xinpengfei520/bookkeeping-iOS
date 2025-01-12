//
//  VerifyController.h
//  bookkeeping
//
//  Created by PengfeiXin on 2022/7/10.
//  Copyright © 2022 kk. All rights reserved.
//

#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^VerifyComplete)(void);

@interface VerifyController : BaseViewController

@property (nonatomic, copy) NSString *phone;
@property (nonatomic, copy) NSString *code;
@property (nonatomic, copy) VerifyComplete complete;

@end

NS_ASSUME_NONNULL_END
