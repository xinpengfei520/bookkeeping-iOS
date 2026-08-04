/**
 * 添加分类
 * @author 郑业强 2018-12-17 创建文件
 * 2026-08-04 XIB → 代码布局（Batch 5），注册方式改 registerClass
 */

#import "ACAReusableHeader.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface ACAReusableHeader()

@property (nonatomic, strong) UILabel *nameLab;

@end


#pragma mark - 实现
@implementation ACAReusableHeader

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

- (void)buildSubviews {
    _nameLab = [[UILabel alloc] init];
    _nameLab.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_nameLab];
    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
}

- (void)initUI {
    [self.nameLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.nameLab setTextColor:kColor_Text_Black];
}


#pragma mark - set
- (void)setModel:(ACAListModel *)model {
    _model = model;
    _nameLab.text = model.name;
}


@end
