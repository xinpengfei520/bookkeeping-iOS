/**
 * item
 * @author 郑业强 2018-12-17 创建文件
 * 2026-08-04 XIB → 代码布局（Batch 6），注册方式改 registerClass
 */

#import "ChartDateCell.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface ChartDateCell()

@property (nonatomic, strong) UILabel *lab;

@end


#pragma mark - 实现
@implementation ChartDateCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

- (void)buildSubviews {
    _lab = [[UILabel alloc] init];
    _lab.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:_lab];
    [_lab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
}

- (void)initUI {
    self.lab.font = LAB_FONT;
}


#pragma mark - set
- (void)setChoose:(BOOL)choose {
    _choose = choose;
    if (choose == YES) {
        _lab.textColor = kColor_Text_Black;
    } else {
        _lab.textColor = kColor_Text_Gary;
    }
}
- (void)setModel:(ChartSubModel *)model {
    _model = model;
    _lab.text = model.detail;
}

@end
