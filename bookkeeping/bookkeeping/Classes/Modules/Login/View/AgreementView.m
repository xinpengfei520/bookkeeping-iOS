#import "AgreementView.h"
#import <Masonry/Masonry.h>

@interface AgreementView()

@property (nonatomic, strong) UIButton *checkBox;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIButton *userAgreementBtn;
@property (nonatomic, strong) UIButton *privacyAgreementBtn;

@end

@implementation AgreementView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.userInteractionEnabled = YES;
    
    // 创建一个容器视图来包含所有内容
    UIView *containerView = [[UIView alloc] init];
    containerView.userInteractionEnabled = YES;
    [self addSubview:containerView];
    
    // 修改复选框的热区
    UIView *checkBoxContainer = [[UIView alloc] init];
    checkBoxContainer.userInteractionEnabled = YES;
    [containerView addSubview:checkBoxContainer];
    
    // 复选框
    _checkBox = [UIButton buttonWithType:UIButtonTypeCustom];
    _checkBox.userInteractionEnabled = YES;
    _checkBox.exclusiveTouch = YES;
    
    // 设置图片内容模式，确保图片不被拉伸
    _checkBox.imageView.contentMode = UIViewContentModeScaleAspectFit;
    _checkBox.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    _checkBox.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _checkBox.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    
    // 设置图片，并指定不拉伸
    UIImage *normalImage = [[UIImage imageNamed:@"checkbox_normal"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *selectedImage = [[UIImage imageNamed:@"checkbox_selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [_checkBox setImage:normalImage forState:UIControlStateNormal];
    [_checkBox setImage:selectedImage forState:UIControlStateSelected];
    
    [_checkBox addTarget:self action:@selector(checkBoxClick:) forControlEvents:UIControlEventTouchUpInside];
    [checkBoxContainer addSubview:_checkBox];
    
    // 文本标签
    _textLabel = [[UILabel alloc] init];
    _textLabel.text = @"我已阅读并同意";
    _textLabel.font = [UIFont systemFontOfSize:12];
    _textLabel.textColor = [UIColor lightGrayColor];
    [containerView addSubview:_textLabel];  // 直接添加到容器视图
    
    // 用户协议按钮
    _userAgreementBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_userAgreementBtn setTitle:@"用户协议" forState:UIControlStateNormal];
    [_userAgreementBtn setTitleColor:kColor_Main_Color forState:UIControlStateNormal];
    _userAgreementBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [_userAgreementBtn addTarget:self action:@selector(userAgreementClick) forControlEvents:UIControlEventTouchUpInside];
    [containerView addSubview:_userAgreementBtn];  // 直接添加到容器视图
    
    // 分隔符
    UILabel *separatorLabel = [[UILabel alloc] init];
    separatorLabel.text = @"、";
    separatorLabel.font = [UIFont systemFontOfSize:12];
    separatorLabel.textColor = [UIColor lightGrayColor];
    [containerView addSubview:separatorLabel];  // 直接添加到容器视图
    
    // 隐私协议按钮
    _privacyAgreementBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_privacyAgreementBtn setTitle:@"隐私协议" forState:UIControlStateNormal];
    [_privacyAgreementBtn setTitleColor:kColor_Main_Color forState:UIControlStateNormal];
    _privacyAgreementBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [_privacyAgreementBtn addTarget:self action:@selector(privacyAgreementClick) forControlEvents:UIControlEventTouchUpInside];
    [containerView addSubview:_privacyAgreementBtn];  // 直接添加到容器视图
    
    // 修改容器视图的约束
    [containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);  // 容器居中
        make.height.equalTo(@44);   // 增加容器高度，确保足够显示选中状态的 checkbox
        make.left.and.right.equalTo(self);  // 容器宽度占满父视图
    }];
    
    // 修改热区容器的约束
    [checkBoxContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(containerView).offset(16);  // 左边留出边距
        make.centerY.equalTo(containerView);
        make.width.and.height.equalTo(@44);  // 保持热区大小
    }];
    
    // 修改复选框的约束
    [_checkBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(checkBoxContainer);
        make.width.and.height.equalTo(@20);  // 固定 checkbox 大小
    }];
    
    // 修改文本标签的约束
    [_textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(checkBoxContainer.mas_right).offset(5);
        make.centerY.equalTo(containerView);
    }];
    
    [_userAgreementBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_textLabel.mas_right);
        make.centerY.equalTo(containerView);
    }];
    
    [separatorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_userAgreementBtn.mas_right);
        make.centerY.equalTo(containerView);
    }];
    
    [_privacyAgreementBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(separatorLabel.mas_right);
        make.right.lessThanOrEqualTo(containerView).offset(-16);  // 右边留出边距
        make.centerY.equalTo(containerView);
    }];
}

#pragma mark - Actions
- (void)checkBoxClick:(UIButton *)sender {
    [UIView animateWithDuration:0.15 
                          delay:0 
                        options:UIViewAnimationOptionCurveEaseInOut 
                     animations:^{
        sender.transform = CGAffineTransformMakeScale(0.8, 0.8);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 
                              delay:0 
                            options:UIViewAnimationOptionCurveEaseInOut 
                         animations:^{
            sender.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            sender.selected = !sender.selected;
            if ([self.delegate respondsToSelector:@selector(agreementViewDidChangeState:)]) {
                [self.delegate agreementViewDidChangeState:sender.selected];
            }
        }];
    }];
}

- (void)userAgreementClick {
    if ([self.delegate respondsToSelector:@selector(agreementViewDidTapUserAgreement)]) {
        [self.delegate agreementViewDidTapUserAgreement];
    }
}

- (void)privacyAgreementClick {
    if ([self.delegate respondsToSelector:@selector(agreementViewDidTapPrivacyAgreement)]) {
        [self.delegate agreementViewDidTapPrivacyAgreement];
    }
}

- (void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    _checkBox.selected = isSelected;
}

// 添加调试方法
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    // 检查点击是否在复选框热区内
    if (CGRectContainsPoint(_checkBox.superview.frame, point)) {
        [self checkBoxClick:_checkBox];
    }
    
    [super touchesBegan:touches withEvent:event];
}

// 添加点击区域调试方法
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    NSLog(@"AgreementView hitTest - point: %@, hitView: %@", NSStringFromCGPoint(point), hitView);
    return hitView;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    BOOL inside = [super pointInside:point withEvent:event];
    NSLog(@"AgreementView pointInside - point: %@, inside: %d", NSStringFromCGPoint(point), inside);
    return inside;
}

// 添加调试方法
- (void)checkBoxTouchDown:(UIButton *)sender {
    NSLog(@"CheckBox touchDown");
}

- (void)checkBoxTouchUpOutside:(UIButton *)sender {
    NSLog(@"CheckBox touchUpOutside");
}

@end 