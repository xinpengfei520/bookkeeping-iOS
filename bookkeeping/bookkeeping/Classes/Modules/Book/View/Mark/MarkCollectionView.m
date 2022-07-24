//
//  显示推荐备注的列表视图
//  MarkCollectionView.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/7/22.
//  Copyright © 2022 kk. All rights reserved.
//

#import "MarkCollectionView.h"
#import "MarkCollectionViewCell.h"

@interface MarkCollectionView()<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, assign) BOOL animation;
@property (nonatomic, strong) NSIndexPath *selectIndex;

@end

@implementation MarkCollectionView

#pragma mark - 初始化
+ (instancetype)initWithFrame:(CGRect)frame {
    MarkCollectionView *collection = [[MarkCollectionView alloc] initWithFrame:frame collectionViewLayout:({
        UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
        flow.itemSize = CGSizeMake(countcoordinatesX(58), frame.size.height-18);
        flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        flow.minimumLineSpacing = countcoordinatesX(6);
        flow.headerReferenceSize = CGSizeMake(countcoordinatesX(78), frame.size.height-18);
        flow;
    })];
    [collection setShowsHorizontalScrollIndicator:NO];
    [collection setBackgroundColor:kColor_White];
    [collection setDelegate:collection];
    [collection setDataSource:collection];
    [collection registerNib:[UINib nibWithNibName:@"MarkCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"MarkCollectionViewCell"];
    [collection registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"MarkCollectionViewHeader"];
    return collection;
}


#pragma mark - 动画
- (void)show:(CGFloat)keyboardHeight {
    if (_animation == YES) {
        return;
    }
    _animation = YES;
    
    [self setHidden:NO];
    [UIView animateWithDuration:.3f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self setTop:SCREEN_HEIGHT - keyboardHeight - self.height];
    } completion:^(BOOL finished) {
        [self setAnimation:NO];
    }];
}

- (void)hide {
    if (_animation == YES) {
        return;
    }
    _animation = YES;
    
    [self setHidden:NO];
    [UIView animateWithDuration:.3f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self setTop:SCREEN_HEIGHT];
    } completion:^(BOOL finished) {
        [self setAnimation:NO];
    }];
}

#pragma mark - set
- (void)setModels:(NSMutableArray<MarkModel *> *)models {
    _models = models;
    if (_selectIndex) {
        _selectIndex = nil;
    }
    [self reloadData];
}


#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.models.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MarkCollectionViewCell *cell = [MarkCollectionViewCell loadItem:collectionView index:indexPath];
    cell.model = self.models[indexPath.row];
    cell.choose = [_selectIndex isEqual:indexPath];
    return cell;
}


#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self collectionDidSelect:indexPath animation:true];
    if (self.complete) {
        MarkModel *model = self.models[indexPath.row];
        self.complete(model);
    }
}

- (void)collectionDidSelect:(NSIndexPath *)indexPath animation:(BOOL)animation {
    [self scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animation];
    [self reloadItemsAtIndexPaths:({
        NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
        if (_selectIndex) {
            [indexPaths addObject:_selectIndex];
        }
        [indexPaths addObject:indexPath];
        _selectIndex = indexPath;
        indexPaths;
    })];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, countcoordinatesX(10));
}

-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    // 视图添加到 UICollectionReusableView 创建的对象中
    if (kind == UICollectionElementKindSectionHeader) {
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"MarkCollectionViewHeader" forIndexPath:indexPath];
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, headerView.width, headerView.height)];
        label.font = [UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight];
        label.textColor = kColor_Text_Black;
        label.text = @"推荐备注";
        label.clipsToBounds = YES;
        label.textAlignment = NSTextAlignmentCenter;
        [headerView addSubview:label];
        return headerView;
    }else {
        return nil;
    }
}


@end
