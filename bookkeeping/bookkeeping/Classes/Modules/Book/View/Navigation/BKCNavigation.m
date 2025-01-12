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
    [_btn1 setTitle:@"支出" forState:UIControlStateNormal];
    [_btn1.titleLabel setFont:BTN_FONT];
    [_btn1 setTitleColor:kColor_Text_White forState:UIControlStateNormal];
    [self addSubview:_btn1];
    
    // 收入按钮
    _btn2 = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btn2 setTitle:@"收入" forState:UIControlStateNormal];
    [_btn2.titleLabel setFont:BTN_FONT];
    [_btn2 setTitleColor:kColor_Text_White forState:UIControlStateNormal];
    [self addSubview:_btn2];
    
    // 取消按钮
    _cancleBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [_cancleBtn setTitle:@"取消" forState:UIControlStateNormal];
    [_cancleBtn setTitleColor:kColor_Text_White forState:UIControlStateNormal];
    [_cancleBtn setTitleColor:kColor_Text_Gary forState:UIControlStateHighlighted];
    [_cancleBtn.titleLabel setFont:[UIFont systemFontOfSize:AdjustFont(14)]];
    [self addSubview:_cancleBtn];
    
    // 底部分割线
    UIView *bottomLine = [[UIView alloc] init];
    bottomLine.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
    [self addSubview:bottomLine];
    
    // 下划线
    CGFloat width = [@"收入" sizeWithMaxSize:CGSizeMake(MAXFLOAT, MAXFLOAT) font:BTN_FONT].width;
    _line = [[UIView alloc] init];
    _line.backgroundColor = kColor_Text_White;
    [self addSubview:_line];
    
    // 设置约束
    [_btn1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(StatusBarHeight + countcoordinatesX(20));
        make.centerX.equalTo(self).offset(-countcoordinatesX(30));
        make.width.equalTo(@(countcoordinatesX(60)));
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
        make.width.equalTo(@(width));
        make.height.equalTo(@2);
        make.centerX.equalTo(_btn1);
    }];
    
    // 添加事件
    @weakify(self)
    [[_btn1 rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self)
        [self routerEventWithName:BOOK_CLICK_NAVIGATION data:@(0)];
    }];
    
    [[_btn2 rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self)
        [self routerEventWithName:BOOK_CLICK_NAVIGATION data:@(1)];
    }];
    
    [[_cancleBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self)
        [self cancleClick:x];
    }];
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
            make.width.equalTo(@([@"收入" sizeWithMaxSize:CGSizeMake(MAXFLOAT, MAXFLOAT) font:BTN_FONT].width));
            make.height.equalTo(@2);
            make.centerX.equalTo(targetBtn);
        }];
        [self layoutIfNeeded];
    }];
}

- (void)setOffsetX:(CGFloat)offsetX {
    _offsetX = offsetX;
    CGFloat moveOffset = offsetX / SCREEN_WIDTH * countcoordinatesX(60);
    
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
