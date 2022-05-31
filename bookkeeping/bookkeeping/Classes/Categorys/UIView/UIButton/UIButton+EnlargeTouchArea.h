//
//  UIButton.h
//  bookkeeping
//
//  Created by PengfeiXin on 2022/5/31.
//  Copyright © 2022 kk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIButton (EnlargeTouchArea)

// 扩大按钮点击范围
- (void)setEnlargeEdgeWithTop:(CGFloat) top right:(CGFloat) right bottom:(CGFloat) bottom left:(CGFloat) left;

@end

