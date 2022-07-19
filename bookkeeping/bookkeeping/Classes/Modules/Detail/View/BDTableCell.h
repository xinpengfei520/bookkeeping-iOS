//
//  BDTableCell.h
//  bookkeeping
//
//  Created by 郑业强 on 2019/1/6.
//  Copyright © 2019年 kk. All rights reserved.
//

#import "BaseTableCell.h"
#import "BookDetailModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTableCell : BaseTableCell

@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) BookDetailModel *model;

@end

NS_ASSUME_NONNULL_END
