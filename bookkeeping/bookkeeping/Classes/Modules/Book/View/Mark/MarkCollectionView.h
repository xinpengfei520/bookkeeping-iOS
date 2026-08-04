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
@property (nonatomic, copy  ) OnSelectComplete complete;

// 初始化
+ (instancetype)initWithFrame:(CGRect)frame;
- (void)show:(CGFloat)keyboardHeight;
- (void)hide;
/// 按备注文案联动选中：用户手输的备注恰好在推荐列表里时，高亮对应项并滚到可见位置；
/// 没匹配上则清掉现有高亮。不回调 complete（避免反向覆盖输入框）。
- (void)selectMarkName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
