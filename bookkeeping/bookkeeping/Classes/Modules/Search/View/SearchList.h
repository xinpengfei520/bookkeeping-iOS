//
//  SearchList.h
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/12.
//  Copyright © 2022 kk. All rights reserved.
//

#import "BaseView.h"

NS_ASSUME_NONNULL_BEGIN

@interface SearchList : BaseView

@property (nonatomic, strong) NSMutableArray<BookMonthModel *> *models;

@end

NS_ASSUME_NONNULL_END
