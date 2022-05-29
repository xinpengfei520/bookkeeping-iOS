//
//  HomeNavigation.h
//  bookkeeping
//
//  Created by 郑业强 on 2019/1/6.
//  Copyright © 2019年 kk. All rights reserved.
//

#import "BaseView.h"

NS_ASSUME_NONNULL_BEGIN

@interface HomeNavigation : BaseView
@property (weak, nonatomic) IBOutlet UIButton *mineButton;
@property (weak, nonatomic) IBOutlet UIButton *statisticsBtn;
@property (weak, nonatomic) IBOutlet UILabel *dateButton;

@end

NS_ASSUME_NONNULL_END
