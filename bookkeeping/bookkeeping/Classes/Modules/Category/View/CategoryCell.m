/**
 * 分类
 * @author 郑业强 2018-12-17 创建文件
 * 2026-08-04 XIB → 代码布局（Batch 8）
 */

#import "CategoryCell.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface CategoryCell()

@property (nonatomic, strong) UIButton *actionBtn;
@property (nonatomic, strong) UIImageView *icon;
@property (nonatomic, strong) UILabel *nameLab;
@property (nonatomic, strong) UILabel *detailLab;
@property (nonatomic, strong) UIButton *menuBtn;
@property (nonatomic, strong) UILongPressGestureRecognizer *longG;

@end


#pragma mark - 实现
@implementation CategoryCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

// 原 XIB：[操作按钮(25)][图标(25)][名称][（自定义）]……[拖动手柄(靠右)]，全部纵向占满
- (void)buildSubviews {
    _actionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.contentView addSubview:_actionBtn];

    _icon = [[UIImageView alloc] init];
    _icon.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:_icon];

    _nameLab = [[UILabel alloc] init];
    [self.contentView addSubview:_nameLab];

    _detailLab = [[UILabel alloc] init];
    [self.contentView addSubview:_detailLab];

    _menuBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_menuBtn setImage:[UIImage imageNamed:@"guide_sort"] forState:UIControlStateNormal];
    [_menuBtn setImage:[UIImage imageNamed:@"guide_sort"] forState:UIControlStateHighlighted];
    [self.contentView addSubview:_menuBtn];

    [_actionBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(15);
        make.top.bottom.equalTo(self.contentView);
        make.width.equalTo(@25);
    }];
    [_icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_actionBtn.mas_right).offset(15);
        make.top.bottom.equalTo(self.contentView);
        make.width.equalTo(self->_actionBtn);
    }];
    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_icon.mas_right).offset(15);
        make.top.bottom.equalTo(self.contentView);
    }];
    [_detailLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_nameLab.mas_right).offset(5);
        make.top.bottom.equalTo(self.contentView);
    }];
    [_menuBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView);
        make.top.bottom.equalTo(self.contentView);
    }];

    [_actionBtn addTarget:self action:@selector(actionClick:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)initUI {
    [self.nameLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight]];
    [self.nameLab setTextColor:kColor_Text_Black];
    [self.detailLab setFont:[UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightUltraLight]];
    [self.detailLab setTextColor:kColor_Text_Gary];
    [self.actionBtn.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self longG];
    // 滑动删除：由 CategoryTable 的 trailingSwipeActionsConfigurationForRowAtIndexPath 接管
}


#pragma mark - 点击
// 删除
- (void)actionClick:(UIButton *)sender {
    [self routerEventWithName:CATEGORY_ACTION_CLICK data:self];
}


#pragma mark - set
- (void)setIndexPath:(NSIndexPath *)indexPath {
    _indexPath = indexPath;
    NSString *image = indexPath.section == 0 ? @"category_delete" : @"category_add";
    [self.actionBtn setImage:[UIImage imageNamed:image] forState:UIControlStateNormal];
    [self.actionBtn setImage:[UIImage imageNamed:image] forState:UIControlStateHighlighted];
    [self refreshEditingControls];
}
- (void)setEditingMode:(BOOL)editingMode {
    _editingMode = editingMode;
    [self refreshEditingControls];
}
// 仅编辑模式显示操作控件；拖动手柄只在 section0（用户分类）可用，section1（已删除）不可拖动
- (void)refreshEditingControls {
    [self.actionBtn setHidden:!_editingMode];
    [self.menuBtn setHidden:!_editingMode || self.indexPath.section != 0];
}
- (void)setModel:(BKCModel *)model {
    _model = model;
    [_nameLab setText:model.name];
    [_detailLab setText:model.is_system == false ? KKLocalized(@"(自定义)") : @""];
    [_icon setImage:[UIImage imageNamed:model.icon_n]];
}


#pragma mark - 手势
- (UILongPressGestureRecognizer *)longG {
    if (!_longG) {
        _longG = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognized:)];
        [self.menuBtn addGestureRecognizer:_longG];
    }
    return _longG;
}
- (void)longPressGestureRecognized:(UILongPressGestureRecognizer *)longG {
    [self routerEventWithName:CATEGORY_LONG_GESTURE data:longG];
}


@end
