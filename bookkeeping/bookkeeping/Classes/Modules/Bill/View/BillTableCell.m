/**
 * 列表Cell (code-only — converted from BillTableCell.xib)
 * @author 郑业强 2019-01-09 创建文件
 */

#import "BillTableCell.h"
#import <Masonry/Masonry.h>


#pragma mark - 声明
@interface BillTableCell()

@property (nonatomic, strong) UILabel *lab1;
@property (nonatomic, strong) UILabel *lab2;
@property (nonatomic, strong) UILabel *lab3;
@property (nonatomic, strong) UILabel *lab4;

@end


#pragma mark - 实现
@implementation BillTableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

- (void)buildSubviews {
    _lab1 = [[UILabel alloc] init];
    [self.contentView addSubview:_lab1];

    _lab2 = [[UILabel alloc] init];
    [self.contentView addSubview:_lab2];

    _lab3 = [[UILabel alloc] init];
    [self.contentView addSubview:_lab3];

    _lab4 = [[UILabel alloc] init];
    [self.contentView addSubview:_lab4];

    // 4 个 label 等宽横排：lab1 从 leading=20 开始，lab2/3/4 各占 lab1.width，
    // lab4 右边 = contentView 右边
    [_lab1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(countcoordinatesX(20));
        make.top.bottom.equalTo(self.contentView);
    }];
    [_lab2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_lab1.mas_right);
        make.top.bottom.equalTo(self->_lab1);
        make.width.equalTo(self->_lab1);
    }];
    [_lab3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_lab2.mas_right);
        make.top.bottom.equalTo(self->_lab1);
        make.width.equalTo(self->_lab1);
    }];
    [_lab4 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_lab3.mas_right);
        make.right.equalTo(self.contentView);
        make.top.bottom.equalTo(self->_lab1);
        make.width.equalTo(self->_lab1);
    }];
}

- (void)initUI {
    for (id obj in self.contentView.subviews) {
        if ([obj isKindOfClass:[UILabel class]]) {
            UILabel *lab = obj;
            lab.font = [UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight];
            lab.textColor = kColor_Text_Black;
        }
    }
    // XIB 静态文本本地化（lab1=月份 lab2=收入 lab3=支出 lab4=结余）。lab1 在 setModel 时
    // 会被 model[@"month"] 覆盖（月份数字），其它三个保持作为 column header。
    [self.lab1 setText:KKLocalized(@"月份")];
    [self.lab2 setText:KKLocalized(@"收入")];
    [self.lab3 setText:KKLocalized(@"支出")];
    [self.lab4 setText:KKLocalized(@"结余")];
}


#pragma mark - set
- (void)setModel:(NSDictionary *)model {
    _model = model;
    [self.lab1 setText:model[@"month"]];
    [self.lab2 setAttributedText:[NSAttributedString createMath:model[@"income"] integer:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight] decimal:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]]];
    [self.lab3 setAttributedText:[NSAttributedString createMath:model[@"pay"] integer:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight] decimal:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]]];
    [self.lab4 setAttributedText:[NSAttributedString createMath:model[@"sum"] integer:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight] decimal:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]]];
}


@end
