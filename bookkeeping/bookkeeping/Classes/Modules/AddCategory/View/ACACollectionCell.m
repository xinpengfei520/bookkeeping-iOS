/**
 * 添加分类
 * @author 郑业强 2018-12-17 创建文件
 * 2026-08-04 XIB → 代码布局（Batch 5），注册方式改 registerClass
 */

#import "ACACollectionCell.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface ACACollectionCell()

@property (nonatomic, strong) UIImageView *icon;

@end


#pragma mark - 实现
@implementation ACACollectionCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

- (void)buildSubviews {
    _icon = [[UIImageView alloc] init];
    [self.contentView addSubview:_icon];
    // 原 XIB：icon 居中 + 左边距 15（运行时改成 countcoordinatesX(15)）+ 宽高 1:1
    [_icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.contentView);
        make.left.equalTo(self.contentView).offset(countcoordinatesX(15));
        make.width.equalTo(self->_icon.mas_height);
    }];
}

#pragma mark - set
- (void)setModel:(ACAModel *)model {
    _model = model;
}
- (void)setChoose:(BOOL)choose {
    _choose = choose;
    if (choose == YES) {
        [_icon setImage:[UIImage imageNamed:_model.icon_s]];
//        [_icon sd_setImageWithURL:[NSURL URLWithString:KStatic(_model.icon_s)]];
    } else {
        [_icon setImage:[UIImage imageNamed:_model.icon_n]];
//        [_icon sd_setImageWithURL:[NSURL URLWithString:KStatic(_model.icon_n)]];
    }
}



@end
