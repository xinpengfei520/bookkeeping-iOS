/**
 * 导航栏
 * @author 郑业强 2018-12-17 创建文件
 * 2026-08-04 XIB → 代码布局（Batch 6）
 */

#import "ChartNavigation.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface ChartNavigation()

@property (nonatomic, strong) UILabel *nameLab;
@property (nonatomic, strong) UIImageView *timeDown;
@property (nonatomic, strong) UILabel *titleLab;
@property (nonatomic, strong) UIButton *backBtn;

@end


#pragma mark - 实现
@implementation ChartNavigation

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
    }
    return self;
}

// 原 XIB 结构（都沉底对齐，高 44 = 导航条内容区）：
//   [返回(44×44)]  居中: [支出 ▾]（button 是盖在它们上面的透明热区）  居中: titleLab
- (void)buildSubviews {
    _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_backBtn setImage:[UIImage imageNamed:@"icon_back_white"] forState:UIControlStateNormal];
    [self addSubview:_backBtn];

    _nameLab = [[UILabel alloc] init];
    _nameLab.text = KKLocalized(@"支出");
    [self addSubview:_nameLab];

    _timeDown = [[UIImageView alloc] init];
    _timeDown.contentMode = UIViewContentModeScaleAspectFit;
    _timeDown.image = [UIImage imageNamed:@"time_down"];
    [self addSubview:_timeDown];

    _titleLab = [[UILabel alloc] init];
    _titleLab.textAlignment = NSTextAlignmentCenter;
    _titleLab.hidden = YES;
    [self addSubview:_titleLab];

    // 透明热区按钮，罩住 [支出 ▾] 两侧各扩 20pt
    _button = [UIButton buttonWithType:UIButtonTypeCustom];
    [self addSubview:_button];

    [_backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.equalTo(self);
        make.width.height.equalTo(@44);
    }];
    [_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.bottom.equalTo(self);
        make.height.equalTo(@44);
    }];
    [_timeDown mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_nameLab.mas_right).offset(3);
        make.centerY.equalTo(self->_nameLab);
        make.width.equalTo(@10);
    }];
    [_titleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.bottom.equalTo(self);
        make.height.equalTo(@44);
    }];
    [self->_button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self);
        make.left.equalTo(self->_nameLab).offset(-20);
        make.right.equalTo(self->_timeDown).offset(20);
    }];

    [_backBtn addTarget:self action:@selector(backClick:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)initUI {
    [self setBackgroundColor:kColor_Main_Color];
    [self.titleLab setFont:[UIFont systemFontOfSize:AdjustFont(14)]];
    [self.titleLab setTextColor:kColor_Text_White];
    [self.nameLab setTextColor:kColor_Text_White];
}


#pragma mark - 点击
- (void)backClick:(UIButton *)sender {
    [self.viewController.navigationController popViewControllerAnimated:true];
}


#pragma mark - set
- (void)setNavigationIndex:(NSInteger)navigationIndex {
    _navigationIndex = navigationIndex;
    if (navigationIndex == 0) {
        _nameLab.text = KKLocalized(@"支出");
    } else {
        _nameLab.text = KKLocalized(@"收入");
    }
}

- (void)setCmodel:(BookDetailModel *)cmodel {
    _cmodel = cmodel;
    if (_cmodel) {
        _nameLab.hidden = true;
        _timeDown.hidden = true;
        _button.hidden = true;
        _backBtn.hidden = false;
        _titleLab.hidden = false;
        BKCModel *category = [NSUserDefaults getCategoryModel:cmodel.categoryId];
        _titleLab.text = category.name;
    } else {
        _nameLab.hidden = false;
        _timeDown.hidden = false;
        _button.hidden = false;
        _backBtn.hidden = false;
        _titleLab.hidden = true;
    }
}


@end
