//
//  UpdateBookModel.h
//  bookkeeping
//
//  Created by PengfeiXin on 2022/7/19.
//  Copyright © 2022 kk. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UpdateBookModel : NSObject<NSCoding, NSCopying>

@property (nonatomic, assign) CGFloat oldPrice;
@property (nonatomic, strong) BookDetailModel *model;

@end

NS_ASSUME_NONNULL_END
