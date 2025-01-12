/**
 * 空白页
 * @author 郑业强 2018-12-28 创建文件
 */

#import "HomeListEmpty.h"
#import <Masonry/Masonry.h>

@interface HomeListEmpty()

@property (nonatomic, strong) UILabel *nameLab;

@end

@implementation HomeListEmpty

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self setUserInteractionEnabled:NO];
    [self setHidden:YES];
    [self setBackgroundColor:[UIColor whiteColor]];
    
    // 无数据标签
    _nameLab = [[UILabel alloc] init];
    _nameLab.text = @"无数据";
    _nameLab.font = [UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight];
    _nameLab.textColor = kColor_Text_Gary;
    _nameLab.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_nameLab];
    
    // 设置约束
    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
    }];
}

@end
