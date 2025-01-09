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
    // 复选框
    _checkBox = [UIButton buttonWithType:UIButtonTypeCustom];
    [_checkBox setImage:[UIImage imageNamed:@"checkbox_normal"] forState:UIControlStateNormal];
    [_checkBox setImage:[UIImage imageNamed:@"checkbox_selected"] forState:UIControlStateSelected];
    [_checkBox addTarget:self action:@selector(checkBoxClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_checkBox];
    
    // 文本标签
    _textLabel = [[UILabel alloc] init];
    _textLabel.text = @"我已阅读并同意";
    _textLabel.font = [UIFont systemFontOfSize:12];
    _textLabel.textColor = [UIColor lightGrayColor];
    [self addSubview:_textLabel];
    
    // 用户协议按钮
    _userAgreementBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_userAgreementBtn setTitle:@"用户协议" forState:UIControlStateNormal];
    [_userAgreementBtn setTitleColor:kColor_Main_Color forState:UIControlStateNormal];
    _userAgreementBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [_userAgreementBtn addTarget:self action:@selector(userAgreementClick) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_userAgreementBtn];
    
    // 分隔符
    UILabel *separatorLabel = [[UILabel alloc] init];
    separatorLabel.text = @"、";
    separatorLabel.font = [UIFont systemFontOfSize:12];
    separatorLabel.textColor = [UIColor lightGrayColor];
    [self addSubview:separatorLabel];
    
    // 隐私协议按钮
    _privacyAgreementBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_privacyAgreementBtn setTitle:@"隐私协议" forState:UIControlStateNormal];
    [_privacyAgreementBtn setTitleColor:kColor_Main_Color forState:UIControlStateNormal];
    _privacyAgreementBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [_privacyAgreementBtn addTarget:self action:@selector(privacyAgreementClick) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_privacyAgreementBtn];
    
    // 创建一个容器视图来包含所有内容
    UIView *containerView = [[UIView alloc] init];
    [self addSubview:containerView];
    
    // 将所有控件添加到容器视图中
    [containerView addSubview:_checkBox];
    [containerView addSubview:_textLabel];
    [containerView addSubview:_userAgreementBtn];
    [containerView addSubview:separatorLabel];
    [containerView addSubview:_privacyAgreementBtn];
    
    // 设置容器视图的约束
    [containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);  // 容器居中
        make.height.equalTo(@20);
    }];
    
    // 修改其他控件的约束，相对于容器视图
    [_checkBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(containerView);
        make.centerY.equalTo(containerView);
        make.width.height.equalTo(@20);
    }];
    
    [_textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_checkBox.mas_right).offset(5);
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
        make.right.equalTo(containerView);  // 设置容器的右边界
        make.centerY.equalTo(containerView);
    }];
}

#pragma mark - Actions
- (void)checkBoxClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    if ([self.delegate respondsToSelector:@selector(agreementViewDidChangeState:)]) {
        [self.delegate agreementViewDidChangeState:sender.selected];
    }
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

@end 