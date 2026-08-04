/**
 * 收入/支出切换
 * @author 郑业强 2018-12-28 创建文件
 * 2026-08-04 XIB → 代码布局（Batch 6）
 */

#import "ChartHUDCell.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface ChartHUDCell()

@property (nonatomic, strong) UILabel *nameLab;
@property (nonatomic, strong) UIImageView *done;

@end


#pragma mark - 实现
@implementation ChartHUDCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

// 原 XIB：[名称(左 15)] …… [√(15pt，右 -15)]
- (void)buildSubviews {
    _nameLab = [[UILabel alloc] init];
    [self.contentView addSubview:_nameLab];

    _done = [[UIImageView alloc] init];
    _done.contentMode = UIViewContentModeScaleAspectFit;
    _done.image = [UIImage imageNamed:@"tally_select_right"];
    [self.contentView addSubview:_done];

    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(15);
        make.top.bottom.equalTo(self.contentView);
    }];
    [_done mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-15);
        make.top.bottom.equalTo(self.contentView);
        make.width.equalTo(@15);
    }];
}

- (void)initUI {
    [self setSelectedBackgroundView:[[UIView alloc] initWithFrame:self.frame]];
    [self.selectedBackgroundView setBackgroundColor:kColor_BG];
    [self.nameLab setFont:[UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(12)]];
    [self.done setHidden:true];
}


#pragma mark - set
- (void)setIndexPath:(NSIndexPath *)indexPath {
    _indexPath = indexPath;
    if (indexPath.row == 0) {
        [self.nameLab setText:KKLocalized(@"支出")];
    } else {
        [self.nameLab setText:KKLocalized(@"收入")];
    }
}

- (void)setChoose:(BOOL)choose {
    _choose = choose;
    _done.hidden = !choose;
}


@end
