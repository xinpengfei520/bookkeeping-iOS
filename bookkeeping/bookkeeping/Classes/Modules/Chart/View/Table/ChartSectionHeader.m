/**
 * 图表头视图
 * @author 郑业强 2018-12-18 创建文件
 * 2026-08-04 XIB → 代码布局（Batch 6）
 */

#import "ChartSectionHeader.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface ChartSectionHeader()

@property (nonatomic, strong) UILabel *nameLab;

@end


#pragma mark - 实现
@implementation ChartSectionHeader

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

- (void)buildSubviews {
    _nameLab = [[UILabel alloc] init];
    [self addSubview:_nameLab];
    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(OUT_PADDING);
        make.top.bottom.equalTo(self);
    }];
}

- (void)initUI {
    [self setBackgroundColor:[UIColor systemBackgroundColor]];
    [self.nameLab setText:KKLocalized(@"支出排行榜")];
    [self.nameLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.nameLab setTextColor:kColor_Text_Black];
}


#pragma mark - set
- (void)setNavigationIndex:(NSInteger)navigationIndex {
    _navigationIndex = navigationIndex;
    if (navigationIndex == 0) {
        [_nameLab setText:KKLocalized(@"支出排行榜")];
    } else {
        [_nameLab setText:KKLocalized(@"收入排行榜")];
    }
}



@end
