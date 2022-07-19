//
//  AssetsHeader.h
//  bookkeeping
//
//  Created by PengfeiXin on 2022/7/8.
//  Copyright © 2022 kk. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssetsHeader : BaseView

@property (weak, nonatomic) IBOutlet UILabel *netAssetsLab;
@property (weak, nonatomic) IBOutlet UILabel *assetsLab;
@property (weak, nonatomic) IBOutlet UILabel *debtLab;

@end

NS_ASSUME_NONNULL_END
