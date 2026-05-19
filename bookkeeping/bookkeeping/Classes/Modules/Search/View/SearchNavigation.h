//
//  SearchNavigation.h
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/2.
//  Copyright © 2022 kk. All rights reserved.
//

#import "BaseView.h"

NS_ASSUME_NONNULL_BEGIN

@interface SearchNavigation : BaseView

@property (nonatomic, strong) UITextField *searchTextField;
@property (nonatomic, strong) UIButton *backBtn;

@end

NS_ASSUME_NONNULL_END
