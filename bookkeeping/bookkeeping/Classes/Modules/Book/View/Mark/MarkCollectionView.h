//
//  显示推荐备注的列表视图
//  MarkCollectionView.h
//  bookkeeping
//
//  Created by PengfeiXin on 2022/7/22.
//  Copyright © 2022 kk. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - typedef
typedef void (^OnSelectComplete)(MarkModel *model);

@interface MarkCollectionView : UICollectionView

@property (nonatomic, strong) NSMutableArray<MarkModel *> *models;
@property (nonatomic, strong) NSIndexPath *selectIndex;
@property (nonatomic, copy  ) OnSelectComplete complete;

// 初始化
+ (instancetype)initWithFrame:(CGRect)frame;
// 刷新当前选中
- (void)reloadSelectIndex;
- (void)show:(CGFloat)keyboardHeight;
- (void)hide;

@end

NS_ASSUME_NONNULL_END
