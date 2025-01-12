/**
 * 列表Cell
 * @author 郑业强 2018-12-16 创建文件
 */

#import "BKCCollectionCell.h"
#import <Masonry/Masonry.h>

@interface BKCCollectionCell()

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation BKCCollectionCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor whiteColor];
    
    // 图标
    _iconImageView = [[UIImageView alloc] init];
    _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:_iconImageView];
    
    // 标题
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.font = [UIFont systemFontOfSize:14];
    _titleLabel.textColor = [UIColor darkGrayColor];
    [self.contentView addSubview:_titleLabel];
    
    // 设置约束
    [_iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.contentView).offset(10);
        make.width.height.equalTo(@44);
    }];
    
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(_iconImageView.mas_bottom).offset(5);
        make.left.right.equalTo(self.contentView);
        make.height.equalTo(@20);
    }];
}

#pragma mark - Setter
- (void)setModel:(BKCModel *)model {
    _model = model;
    
    
    if (self.isChoose) {
        _titleLabel.textColor = kColor_Main_Color;
        // 设置图标
        UIImage *icon = [UIImage imageNamed:_model.icon_s];
        // 选中状态，图标着色为主题色
        icon = [self tintImage:icon withColor:kColor_Main_Color];
        _iconImageView.image = icon;
    }else{
        // 设置图标
        UIImage *icon = [UIImage imageNamed:_model.icon_n];
        _iconImageView.image = icon;
    }
    
    
    // 设置标题
    _titleLabel.text = model.name;
}

- (void)setChoose:(BOOL)choose {
    _choose = choose;
    
    if (choose) {
        // 选中状态
        _titleLabel.textColor = kColor_Main_Color;
        _iconImageView.image = [self tintImage:[UIImage imageNamed:_model.icon_s] withColor:kColor_Main_Color];
    } else {
        // 未选中状态
        _titleLabel.textColor = [UIColor darkGrayColor];
        _iconImageView.image = [UIImage imageNamed:_model.icon_n];
    }
}

#pragma mark - Helper
// 图片着色方法
- (UIImage *)tintImage:(UIImage *)image withColor:(UIColor *)color {
    UIImage *newImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIGraphicsBeginImageContextWithOptions(image.size, NO, newImage.scale);
    [color set];
    [newImage drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
