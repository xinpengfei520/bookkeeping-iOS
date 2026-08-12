/**
 * 图表
 * @author 郑业强 2018-12-17 创建文件
 */

#import "ChartDate.h"
#import "ChartDateCell.h"
#import "BookDetailModel.h"

#pragma mark - 声明
@interface ChartDate()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collection;
@property (nonatomic, strong) UIView *line;

@end


#pragma mark - 实现
@implementation ChartDate


- (void)initUI {
    [self setBackgroundColor:[UIColor systemBackgroundColor]];
    [self collection];
    [self line];
    [self borderForColor:kColor_Line_Gray borderWidth:1.f borderType:UIBorderSideTypeBottom];
}


#pragma mark - 操作
// 重建三个维度（周/月/年）的日期列表。
//
// 线程模型（2026-08-05 修复崩溃）：本方法可能在 ChartController 的后台
// NSOperationQueue 上被调用 —— 计算全部写入局部变量，算完后一次性在主线程
// 提交给 sModels / selectIndexs 并刷新。旧实现直接在后台线程改这两个 UI 数据源，
// 与主线程的 reload/collectionDidSelect 竞态：主线程拿着旧"周"列表的下标（如 397）
// 撞上刚被换成的"月"列表（91 个元素）→ NSRangeException 闪退。
// 以前 formatter/calendar 逐次新建让重建慢几百 ms，竞态窗口错开侥幸不崩；
// 读路径提速后窗口对齐，必须结构性修复。
- (void)updateDateRange {
    BookDetailModel *minModel = _minModel;
    BookDetailModel *maxModel = _maxModel;
    if (!minModel || !maxModel) {
        return;
    }

    NSDate *minDate = minModel.date;
    NSDate *maxDate = maxModel.date;
    NSDate *today = [NSDate date];

    // ---- 周 ----
    NSMutableArray<ChartSubModel *> *weekModels = [NSMutableArray array];
    NSIndexPath *weekSelect = nil;
    NSInteger weeks = [NSDate compareWeek:minDate withDate:maxDate];
    for (NSInteger i = 0; i < weeks; i++) {
        NSDate *newDate = [minDate offsetDays:i * 7];
        newDate = [newDate offsetDays:-[newDate weekday] + 1];
        ChartSubModel *submodel = [ChartSubModel init];
        [submodel setYear:[newDate year]];
        [submodel setMonth:[newDate month]];
        [submodel setDay:[newDate day]];
        [submodel setWeek:[newDate weekOfYear]];
        [submodel setWeek_day:[newDate weekday]];
        [submodel setSelectIndex:0];
        [weekModels addObject:submodel];

        if (weekSelect == nil && [[submodel detail] isEqualToString:KKLocalized(@"本周")]) {
            weekSelect = [NSIndexPath indexPathForRow:i inSection:0];
        }
    }
    if (weekSelect == nil && weekModels.count > 0) {
        weekSelect = [NSIndexPath indexPathForRow:weekModels.count - 1 inSection:0];
    }

    // ---- 月 ----
    NSMutableArray<ChartSubModel *> *monthModels = [NSMutableArray array];
    NSIndexPath *monthSelect = nil;
    for (NSInteger y = minDate.year; y <= maxDate.year; y++) {
        NSInteger min_month = (y == minDate.year ? minDate.month : 1);
        NSInteger max_month = (y == maxDate.year ? maxDate.month : 12);
        for (NSInteger m = min_month; m <= max_month; m++) {
            ChartSubModel *submodel = [ChartSubModel init];
            [submodel setYear:y];
            [submodel setMonth:m];
            [submodel setSelectIndex:1];
            [monthModels addObject:submodel];

            if (monthSelect == nil && y == today.year && m == today.month) {
                monthSelect = [NSIndexPath indexPathForRow:monthModels.count - 1 inSection:0];
            }
        }
    }
    if (monthSelect == nil && monthModels.count > 0) {
        monthSelect = [NSIndexPath indexPathForRow:monthModels.count - 1 inSection:0];
    }

    // ---- 年 ----
    NSMutableArray<ChartSubModel *> *yearModels = [NSMutableArray array];
    NSIndexPath *yearSelect = nil;
    for (NSInteger y = minDate.year; y <= maxDate.year; y++) {
        ChartSubModel *submodel = [ChartSubModel init];
        [submodel setYear:y];
        [submodel setSelectIndex:2];
        [yearModels addObject:submodel];
        if (yearSelect == nil && y == today.year) {
            yearSelect = [NSIndexPath indexPathForRow:yearModels.count - 1 inSection:0];
        }
    }
    if (yearSelect == nil && yearModels.count > 0) {
        yearSelect = [NSIndexPath indexPathForRow:yearModels.count - 1 inSection:0];
    }

    NSIndexPath *fallback = [NSIndexPath indexPathForRow:0 inSection:0];
    NSArray *newSelects = @[weekSelect ?: fallback, monthSelect ?: fallback, yearSelect ?: fallback];

    // ---- 主线程原子提交 + 刷新 ----
    @weakify(self)
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self)
        [self.sModels replaceObjectAtIndex:0 withObject:weekModels];
        [self.sModels replaceObjectAtIndex:1 withObject:monthModels];
        [self.sModels replaceObjectAtIndex:2 withObject:yearModels];
        [self.selectIndexs removeAllObjects];
        [self.selectIndexs addObjectsFromArray:newSelects];
        [self.collection reloadData];
        if (self.segmentIndex < (NSInteger)self.selectIndexs.count) {
            [self collectionDidSelect:self.selectIndexs[self.segmentIndex] animation:false];
        }
    });
}


#pragma mark - set
// min/max 总是成对更新，用组合 setter 只触发一次重建
- (void)setMinModel:(BookDetailModel *)minModel maxModel:(BookDetailModel *)maxModel {
    _minModel = minModel;
    _maxModel = maxModel;
    [self updateDateRange];
}

- (void)setMinModel:(BookDetailModel *)minModel {
    [self setMinModel:minModel maxModel:_maxModel];
}

- (void)setMaxModel:(BookDetailModel *)maxModel {
    [self setMinModel:_minModel maxModel:maxModel];
}

- (void)setSegmentIndex:(NSInteger)segmentIndex {
    _segmentIndex = segmentIndex;
    [self reloadDataOnMainThread];
}

- (void)reloadDataOnMainThread{
    @weakify(self)
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self)
        [self.collection reloadData];
        if (self.segmentIndex < self.selectIndexs.count) {
            [self collectionDidSelect:self.selectIndexs[self.segmentIndex] animation:false];
        }
    });
}

- (void)setNavigationIndex:(NSInteger)navigationIndex {
    _navigationIndex = navigationIndex;
    [self updateDateRange];
}


#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.sModels[self.segmentIndex].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ChartDateCell *cell = [ChartDateCell loadItem:collectionView index:indexPath];
    if (self.segmentIndex < self.selectIndexs.count) {
        cell.choose = [self.selectIndexs[self.segmentIndex] isEqual:indexPath];
    }else{
        cell.choose = NO;
    }
    cell.model = self.sModels[self.segmentIndex][indexPath.row];
    return cell;
}


#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self collectionDidSelect:indexPath animation:true];
    // 回调
    if (self.complete) {
        ChartSubModel *model = self.sModels[self.segmentIndex][indexPath.row];
        self.complete(model);
    }
}

- (void)collectionDidSelect:(NSIndexPath *)indexPath animation:(BOOL)animation {
    // 边界保护：数据源与选中下标都可能在重建间隙里过期，脏下标直接丢弃
    if (self.segmentIndex >= (NSInteger)self.sModels.count ||
        self.segmentIndex >= (NSInteger)self.selectIndexs.count ||
        indexPath.row >= (NSInteger)self.sModels[self.segmentIndex].count) {
        return;
    }
    // 移动
    [self.collection scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animation];
    // 刷新
    [self.collection reloadItemsAtIndexPaths:({
        NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
        if (self.selectIndexs[self.segmentIndex]) {
            [indexPaths addObject:self.selectIndexs[self.segmentIndex]];
        }
        [indexPaths addObject:indexPath];
        [self.selectIndexs replaceObjectAtIndex:self.segmentIndex withObject:indexPath];
        indexPaths;
    })];
    
    // 移动
    NSTimeInterval duration = animation == true ? 0.3f : 0;
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        ChartSubModel *model = self.sModels[self.segmentIndex][indexPath.row];
        self.line.width = [model.detail sizeWithMaxSize:CGSizeMake(MAXFLOAT, MAXFLOAT) font:LAB_FONT].width;
        
        CGFloat left = countcoordinatesX(80) * indexPath.row;
        left += indexPath.row != 0 ? indexPath.row * countcoordinatesX(10) : 0;
        left += countcoordinatesX(80) / 2;
        self.line.centerX = left;
    } completion:nil];
}


#pragma mark - get
- (UICollectionView *)collection {
    if (!_collection) {
        _collection = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, self.height) collectionViewLayout:({
            UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
            flow.itemSize = CGSizeMake(countcoordinatesX(80), self.height);
            flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            flow.minimumLineSpacing = countcoordinatesX(10);
            flow;
        })];
        [_collection setShowsHorizontalScrollIndicator:NO];
        [_collection setBackgroundColor:[UIColor systemBackgroundColor]];
        [_collection setDelegate:self];
        [_collection setDataSource:self];
        [_collection registerClass:ChartDateCell.class forCellWithReuseIdentifier:@"ChartDateCell"];
        [self addSubview:_collection];
    }
    return _collection;
}

- (UIView *)line {
    if (!_line) {
        _line = [[UIView alloc] initWithFrame:({
            // width = item width + item space (80 + 10)
            CGFloat width = 90;
            CGFloat height = 2;
            CGFloat left = 0;
            CGFloat top = self.height - height;
            CGRectMake(left, top, width, height);
        })];
        _line.backgroundColor = kColor_Text_Black;
        [self.collection addSubview:_line];
    }
    return _line;
}

- (NSMutableArray<NSIndexPath *> *)selectIndexs {
    if (!_selectIndexs) {
        _selectIndexs = [NSMutableArray array];
    }
    return _selectIndexs;
}

- (NSMutableArray<NSMutableArray<ChartSubModel *> *> *)sModels {
    if (!_sModels) {
        _sModels = [NSMutableArray array];
        [_sModels addObject:[NSMutableArray array]];
        [_sModels addObject:[NSMutableArray array]];
        [_sModels addObject:[NSMutableArray array]];
    }
    return _sModels;
}


@end
