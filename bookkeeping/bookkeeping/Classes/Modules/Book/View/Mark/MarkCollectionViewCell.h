//
//  MarkCollectionViewCell.h
//  bookkeeping
//
//  Created by PengfeiXin on 2022/7/22.
//  Copyright © 2022 kk. All rights reserved.
//

#import "BaseCollectionCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface MarkCollectionViewCell : BaseCollectionCell

@property (nonatomic,strong)MarkModel *model;
@property (nonatomic, assign) BOOL choose;

@end

NS_ASSUME_NONNULL_END
