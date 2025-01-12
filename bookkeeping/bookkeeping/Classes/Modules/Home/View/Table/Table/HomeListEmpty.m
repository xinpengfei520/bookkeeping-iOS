/**
 * 空白页
 * @author 郑业强 2018-12-28 创建文件
 */

#import "HomeListEmpty.h"
#import <Masonry/Masonry.h>

@interface HomeListEmpty()

@property (nonatomic, strong) UIImageView *iconView;
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
    
    // 空状态图标
    _iconView = [[UIImageView alloc] init];
    _iconView.image = [UIImage imageNamed:@"icon_empty_list"];
    _iconView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:_iconView];
    
    // 无数据标签
    _nameLab = [[UILabel alloc] init];
    _nameLab.text = @"空空如也～";
    _nameLab.font = [UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight];
    _nameLab.textColor = kColor_Text_Gary;
    _nameLab.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_nameLab];
    
    // 创建一个容器视图来包含图标和文字，以便于整体居中
    UIView *containerView = [[UIView alloc] init];
    [self addSubview:containerView];
    [containerView addSubview:_iconView];
    [containerView addSubview:_nameLab];
    
    // 设置约束
    [containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self); // 容器整体居中
        make.width.lessThanOrEqualTo(self);
    }];
    
    [_iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(containerView);
        make.centerX.equalTo(containerView);
        make.size.mas_equalTo(CGSizeMake(60, 60)); // 根据实际图片大小调整
    }];
    
    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_iconView.mas_bottom).offset(10);
        make.centerX.equalTo(containerView);
        make.bottom.equalTo(containerView);
    }];
}

- (void)updateEmptyText:(NSString *)text {
    _nameLab.text = text;
}

@end
