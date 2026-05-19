/**
 * 定时 (code-only — converted from TITableCell.xib)
 * @author 郑业强 2018-12-18 创建文件
 */

#import "TITableCell.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface TITableCell()

@property (nonatomic, strong) UILabel *nameLab;
@property (nonatomic, strong) UILabel *detailLab;
@property (nonatomic, strong) UILabel *dayLab;

@end


#pragma mark - 实现
@implementation TITableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self buildSubviews];
        [self setupUI];
    }
    return self;
}

- (void)buildSubviews {
    _nameLab = [[UILabel alloc] init];
    [self.contentView addSubview:_nameLab];

    _dayLab = [[UILabel alloc] init];
    _dayLab.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:_dayLab];

    _detailLab = [[UILabel alloc] init];
    _detailLab.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:_detailLab];

    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(countcoordinatesX(15));
        make.top.bottom.equalTo(self.contentView);
    }];
    // detailLab 宽度按 "00:00" 文本宽 + 5 设；先用占位 50，setupUI 里 update
    [_detailLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-countcoordinatesX(15));
        make.top.bottom.equalTo(self.contentView);
        make.width.equalTo(@50);
    }];
    // dayLab 紧贴在 detailLab 左边（intrinsic 宽，无显式 width 约束）
    [_dayLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self->_detailLab.mas_left);
        make.top.bottom.equalTo(self.contentView);
    }];
}

- (void)setupUI {
    [self setBackgroundColor:[UIColor systemBackgroundColor]];
    // XIB 静态文本：dayLab="每天"
    [self.dayLab setText:KKLocalized(@"每天")];

    [self.nameLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.nameLab setTextColor:kColor_Text_Gary];
    [self.detailLab setFont:[UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(12)]];
    [self.detailLab setTextColor:kColor_Text_Gary];
    [self.dayLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.dayLab setTextColor:kColor_Text_Gary];
    // detailLab width 按当前 font 下 "00:00" 实际宽度 + 5 自适应（避免国际化字体差异）
    CGFloat timeW = [@"00:00" sizeWithMaxSize:CGSizeMake(MAXFLOAT, MAXFLOAT) font:self.detailLab.font].width + 5;
    [self.detailLab mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(timeW));
    }];
}

#pragma mark - set
- (void)setTime:(NSString *)time {
    _time = time;
    _nameLab.text = KKLocalized(@"提醒时间");
    _detailLab.text = time;
}

@end
