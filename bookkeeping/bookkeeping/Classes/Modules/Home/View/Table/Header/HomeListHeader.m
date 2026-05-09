/**
 * 头视图（code-only — pilot conversion from HomeListHeader.xib）
 * @author 郑业强 2018-12-18 创建文件
 */

#import "HomeListHeader.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface HomeListHeader()

@property (nonatomic, strong) UILabel *nameLab;
@property (nonatomic, strong) UILabel *detailLab;
@property (nonatomic, strong) UIView *line;

@end


#pragma mark - 实现
@implementation HomeListHeader

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        [self buildSubviews];
        [self initUI];
    }
    return self;
}

- (void)buildSubviews {
    // UITableViewHeaderFooterView 的背景必须走 backgroundView，直接 setBackgroundColor
    // 在不同 iOS 版本上行为不一致，且 iOS 14+ 会建议改用 backgroundConfiguration。
    UIView *bg = [[UIView alloc] init];
    bg.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.backgroundView = bg;

    _nameLab = [[UILabel alloc] init];
    [self.contentView addSubview:_nameLab];

    _detailLab = [[UILabel alloc] init];
    _detailLab.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:_detailLab];

    _line = [[UIView alloc] init];
    _line.backgroundColor = [UIColor systemGroupedBackgroundColor];
    [self.contentView addSubview:_line];

    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(countcoordinatesX(15));
        make.top.bottom.equalTo(self.contentView);
    }];
    [_line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.contentView);
        make.height.equalTo(@0.5);
    }];
    [_detailLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-countcoordinatesX(15));
        make.top.equalTo(self.contentView);
        make.bottom.equalTo(self->_line.mas_top);
    }];
}

- (void)initUI {
    [self.nameLab setFont:[UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(10)]];
    [self.nameLab setTextColor:kColor_Text_Gary];
    [self.detailLab setFont:[UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(10)]];
    [self.detailLab setTextColor:kColor_Text_Gary];
}


#pragma mark - set
- (void)setModel:(BookMonthModel *)model {
    _model = model;
    [_nameLab setText:[model getDateDescribe]];
    [_detailLab setText:[model getMoneyDescribe]];
}


@end
