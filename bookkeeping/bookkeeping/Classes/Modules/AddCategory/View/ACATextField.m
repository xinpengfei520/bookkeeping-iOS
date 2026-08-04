/**
 * 添加分类
 * @author 郑业强 2018-12-17 创建文件
 * 2026-08-04 XIB → 代码布局（Batch 5）
 */

#import "ACATextField.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface ACATextField()<UITextFieldDelegate>

@property (nonatomic, strong) UIImageView *icon;
@property (nonatomic, strong) UIView *line;

@end


#pragma mark - 实现
@implementation ACATextField

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

// 原 XIB：[icon(40, aspectFit)][输入框]，底部 1px 分隔线
- (void)buildSubviews {
    _icon = [[UIImageView alloc] init];
    _icon.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:_icon];

    _textField = [[UITextField alloc] init];
    _textField.returnKeyType = UIReturnKeyDone;
    _textField.delegate = self;
    [self addSubview:_textField];

    _line = [[UIView alloc] init];
    [self addSubview:_line];

    [_icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(15);
        make.top.bottom.equalTo(self);
        make.width.equalTo(@40);
    }];
    [_textField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_icon.mas_right).offset(10);
        make.right.equalTo(self).offset(-15);
        make.top.bottom.equalTo(self);
    }];
    [_line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.height.equalTo(@1);
    }];
}

- (void)initUI {
    [self.line setBackgroundColor:kColor_Line_Color];
    [self setBackgroundColor:kColor_BG];
    [self.textField setFont:[UIFont systemFontOfSize:14]];
    [self.textField setPlaceholder:KKLocalized(@"请输入类别名称(不超过4个汉字)")];
    [self.textField addTarget:self action:@selector(textChange:) forControlEvents:UIControlEventEditingChanged];
}


- (void)textChange:(UITextField *)textField {
    if (textField.text.length > 4) {
        textField.text = [textField.text substringWithRange:NSMakeRange(0, 4)];
    }
}


#pragma mark - set
- (void)setModel:(ACAModel *)model {
    _model = model;
    [_icon setImage:[UIImage imageNamed:model.icon_s]];
}


#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField endEditing:YES];
    return YES;
}


@end
