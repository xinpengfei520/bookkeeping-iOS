/**
 * 添加记账导航栏
 * @author 郑业强 2018-12-18 创建文件
 */

#import "BKCNavigation.h"
#import "BOOK_EVENT.h"
#import <Masonry/Masonry.h>

#define BTN_FONT [UIFont systemFontOfSize:AdjustFont(16)]

@interface BKCNavigation()

@property (nonatomic, strong) UIButton *btn1;
@property (nonatomic, strong) UIButton *btn2;
@property (nonatomic, strong) UIView *line;
@property (nonatomic, strong) UIButton *cancleBtn;
/// 按钮 + 下划线的实际宽度（按当前语言下"支出"/"收入"两个 title 的较宽
/// 者 + 24pt padding 算）。setOffsetX: 滑动 line 时也用它做基础刻度。
@property (nonatomic, assign) CGFloat btnWidth;

@end

@implementation BKCNavigation

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self setBackgroundColor:kColor_Main_Color];
    
    // 支出按钮
    _btn1 = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btn1 setTitle:KKLocalized(@"支出") forState:UIControlStateNormal];
    [_btn1.titleLabel setFont:BTN_FONT];
    [_btn1 setTitleColor:kColor_Text_White forState:UIControlStateNormal];
    [self addSubview:_btn1];
    
    // 收入按钮
    _btn2 = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btn2 setTitle:KKLocalized(@"收入") forState:UIControlStateNormal];
    [_btn2.titleLabel setFont:BTN_FONT];
    [_btn2 setTitleColor:kColor_Text_White forState:UIControlStateNormal];
    [self addSubview:_btn2];
    
    // 取消按钮
    _cancleBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [_cancleBtn setTitle:KKLocalized(@"取消") forState:UIControlStateNormal];
    [_cancleBtn setTitleColor:kColor_Text_White forState:UIControlStateNormal];
    [_cancleBtn setTitleColor:kColor_Text_Gary forState:UIControlStateHighlighted];
    [_cancleBtn.titleLabel setFont:[UIFont systemFontOfSize:AdjustFont(14)]];
    [self addSubview:_cancleBtn];
    
    // 底部分割线
    UIView *bottomLine = [[UIView alloc] init];
    bottomLine.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
    [self addSubview:bottomLine];
    
    // 按钮宽度按当前语言下两个 title 的较宽者 + padding 算 —— 之前固定
    // countcoordinatesX(60) ≈ 64pt 对中文"支出/收入"够用，但英文 "Expense"
    // (~52pt) / "Income" (~44pt) 加按钮内边距就触发 truncate 出 `[...]`.
    CGFloat title1Width = [KKLocalized(@"支出") sizeWithMaxSize:CGSizeMake(MAXFLOAT, MAXFLOAT) font:BTN_FONT].width;
    CGFloat title2Width = [KKLocalized(@"收入") sizeWithMaxSize:CGSizeMake(MAXFLOAT, MAXFLOAT) font:BTN_FONT].width;
    self.btnWidth = MAX(title1Width, title2Width) + 24; // 两侧各 12pt padding

    // 下划线宽度 = 按钮容器宽（线条比较显眼，跟容器同宽视觉舒服）
    _line = [[UIView alloc] init];
    _line.backgroundColor = kColor_Text_White;
    [self addSubview:_line];

    // 设置约束 —— 两按钮宽都用 self.btnWidth；centerX 偏移也按 btnWidth 的
    // 一半，让两按钮紧贴居中且整体不重叠。
    [_btn1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(StatusBarHeight + countcoordinatesX(20));
        make.centerX.equalTo(self).offset(-self.btnWidth / 2);
        make.width.equalTo(@(self.btnWidth));
        make.bottom.equalTo(self);
    }];

    [_btn2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.width.bottom.equalTo(_btn1);
        make.left.equalTo(_btn1.mas_right);
    }];
    
    [_cancleBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self);
        make.bottom.equalTo(self);
        make.width.equalTo(@(countcoordinatesX(60)));
        make.height.equalTo(@40);
    }];
    
    [bottomLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.height.equalTo(@1);
    }];
    
    [_line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self).offset(-2);
        make.width.equalTo(@(self.btnWidth));
        make.height.equalTo(@2);
        make.centerX.equalTo(_btn1);
    }];
    
    // 添加事件
    @weakify(self)
    [_btn1 kk_addEventHandler:^(__kindof UIControl * _Nullable x) {
        @strongify(self)
        [self routerEventWithName:BOOK_CLICK_NAVIGATION data:@(0)];
    } forControlEvents:UIControlEventTouchUpInside];
    
    [_btn2 kk_addEventHandler:^(__kindof UIControl * _Nullable x) {
        @strongify(self)
        [self routerEventWithName:BOOK_CLICK_NAVIGATION data:@(1)];
    } forControlEvents:UIControlEventTouchUpInside];
    
    [_cancleBtn kk_addEventHandler:^(__kindof UIControl * _Nullable x) {
        @strongify(self)
        [self cancleClick:x];
    } forControlEvents:UIControlEventTouchUpInside];
}

- (void)setIndex:(NSInteger)index {
    [self setIndex:index animation:NO];
}

- (void)setIndex:(NSInteger)index animation:(BOOL)animation {
    _index = index;
    NSTimeInterval time = animation == true ? 0.3f : 0;
    
    UIButton *targetBtn = index == 0 ? _btn1 : _btn2;
    [UIView animateWithDuration:time animations:^{
        [self.line mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self).offset(-2);
            make.width.equalTo(@(self.btnWidth));
            make.height.equalTo(@2);
            make.centerX.equalTo(targetBtn);
        }];
        [self layoutIfNeeded];
    }];
}

- (void)setOffsetX:(CGFloat)offsetX {
    _offsetX = offsetX;
    // 滑动 line 的距离 = 容器滑动比例 × 单按钮宽。固定 60 → 用 self.btnWidth
    // 后能随语言自适应（"Expense" 比 "支出" 宽，line 跟着拉伸）。
    CGFloat moveOffset = offsetX / SCREEN_WIDTH * self.btnWidth;

    [_line mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_btn1).offset(moveOffset);
    }];
}

- (void)cancleClick:(UIButton *)sender {
    if (self.viewController.navigationController.viewControllers.count != 1) {
        [self.viewController.navigationController popViewControllerAnimated:true];
    } else {
        [self.viewController.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
