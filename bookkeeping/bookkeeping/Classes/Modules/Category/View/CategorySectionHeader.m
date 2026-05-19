/**
 * 头视图（code-only — converted from CategorySectionHeader.xib）
 * @author 郑业强 2018-12-19 创建文件
 */

#import "CategorySectionHeader.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface CategorySectionHeader()

@property (nonatomic, strong) UILabel *nameLab;

@end


#pragma mark - 实现
@implementation CategorySectionHeader

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
        [self initUI];
    }
    return self;
}

- (void)buildSubviews {
    _nameLab = [[UILabel alloc] init];
    [self addSubview:_nameLab];

    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(countcoordinatesX(15));
        make.bottom.equalTo(self).offset(-countcoordinatesX(10));
    }];
}

- (void)initUI {
    [self.nameLab setText:KKLocalized(@"更多类别")];
    [self.nameLab setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
    [self.nameLab setTextColor:kColor_Text_Black];
}


@end
