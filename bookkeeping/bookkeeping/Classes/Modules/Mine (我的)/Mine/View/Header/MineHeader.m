/**
 * 我的页面头视图
 * @author 郑业强 2018-12-16 创建文件
 */

#import "MineHeader.h"
#import <Masonry/Masonry.h>

@interface MineHeader()

@property (nonatomic, strong) UILabel *nameLab;

@end

@implementation MineHeader

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = kColor_Main_Color;
    self.alpha = 0;
    
    // 标题
    _nameLab = [[UILabel alloc] init];
    _nameLab.text = @"我的";
    _nameLab.font = [UIFont systemFontOfSize:AdjustFont(15)];
    _nameLab.textColor = kColor_Text_White;
    _nameLab.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_nameLab];
    
    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self);
        make.bottom.equalTo(self);
        make.height.equalTo(@44);
    }];
}

@end
