//
//  SearchListCell.h
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/12.
//  Copyright © 2022 kk. All rights reserved.
//

#import "BaseTableCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface SearchListCell : BaseTableCell

@property (nonatomic, strong) NSMutableArray<BookMonthModel *> *models;

@end

NS_ASSUME_NONNULL_END
