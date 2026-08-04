//
//  KKEmptyLoading.m
//  imiss-ios-master
//
//  Created by 郑业强 on 2018/11/3.
//  Copyright © 2018年 kk. All rights reserved.
//

#import "KKEmptyLoading.h"

#define Shadow_Tag 100

#pragma mark - 声明
@interface KKEmptyLoading()

@property (nonatomic, strong) UIImageView *icn;
@property (nonatomic, strong) UILabel *nameLab;
@property (nonatomic, strong) UILabel *detailLab;

@end


#pragma mark - 实现
@implementation KKEmptyLoading


- (void)initUI {
    [self icn];
    [self nameLab];
    [self detailLab];
}


#pragma mark - 动画
- (void)show {
    for (int i=0; i<14; i++) {
        [self showLoadingAnimation:nil];
    }
    [self bringSubviewToFront:self.icn];
    [self bringSubviewToFront:self.nameLab];
}
- (void)hide {
    [self removeLoadingView];
}


#pragma mark - set
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    CGFloat width = frame.size.width;
    CGFloat height = frame.size.height;
    
    _icn.frame = CGRectMake((width - self.icn.width) / 2,
                            (height - self.icn.height) / 2 - 40,
                            self.icn.width,
                            self.icn.height);
    _nameLab.frame = CGRectMake(0, self.icn.bottom + 8, SCREEN_WIDTH, 20);
    _detailLab.frame = CGRectMake(0, self.nameLab.bottom + 8, SCREEN_WIDTH, 20);
}


#pragma mark - 动画
// 等待动画
- (void)showLoadingAnimation:(NSString *)icn {
    UIImageView *view = [self createRandowView:icn];
    [self createRotationAnimation:view value:0.8];
    [self createRandomAnimation:view icn:icn isLoop:YES];
}
- (void)showLoadingAnimation:(NSString *)icn center:(CGPoint)cnter {
    UIImageView *view = [self createRandowView:icn];
    view.center = cnter;
    [self createRotationAnimation:view value:0.8];
    [self createRandomAnimation:view icn:icn isLoop:NO];
}
// 删除等待动画
- (void)removeLoadingView {
    for (UIView *view in self.subviews) {
        if (view.tag == Shadow_Tag) {
            [view.layer removeAllAnimations];
            [view removeFromSuperview];
        }
    }
}
// 随机点
- (CGPoint)createRandomPoint {
    CGFloat left = random() % (int)self.width;
    CGFloat top = random() % (int)self.height;
    CGPoint center = CGPointMake(left + 10, top + 10);
    CGRect rect = CGRectMake(self.icn.left - 10,
                             self.icn.top - 10,
                             self.icn.width + 20,
                             self.icn.height + 20);
    
    if (CGRectContainsPoint(rect, center)) {
        return [self createRandomPoint];
    }
    return center;
}
// 创建随机控件
- (UIImageView *)createRandowView:(NSString *)icn {
    UIImageView *view = [[UIImageView alloc] initWithFrame:({
        CGPoint position = [self createRandomPoint];
        CGRectMake(position.x, position.y, 20, 20);
    })];
    [view setTag:Shadow_Tag];
    [view setContentMode:UIViewContentModeScaleAspectFit];
    if (icn) {
        [view setImage:[UIImage imageNamed:icn]];
    }
    else {
        NSArray *arr = @[@"loading_cha",@"loading_san",@"loading_yuan"];
        [view setImage:[UIImage imageNamed:arr[random() % 3]]];
    }
    [self insertSubview:view belowSubview:self.icn];
    return view;
}
// 创建动画（原用 pop 实现，pop 已移除 —— 改成 UIView 动画 + Core Animation，行为一致：
// 碎片匀速飘向中心并缓慢自转，到达后消失，isLoop 时再补一个新碎片）
- (void)createRandomAnimation:(UIImageView *)view icn:(NSString *)icn isLoop:(BOOL)isLoop {
    CGPoint point1 = view.center;
    CGPoint point2 = self.center;

    CGFloat length = pow(ABS(point1.x - point2.x), 2);
    length += pow(ABS(point1.y - point2.y), 2);
    length = sqrt(length);

    // 自转：50s 转 15 圈的匀速旋转（额外挂在 layer 上，不影响 center 动画）
    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotation.toValue = @(M_PI * 30);
    rotation.duration = 50;
    rotation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [view.layer addAnimation:rotation forKey:@"rotation"];

    // 位移：匀速飘向中心，速度恒定（时长 = 距离 / 30pt每秒）
    [UIView animateWithDuration:length / 30.f
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
        view.center = CGPointMake(self.width / 2, self.height / 2);
    } completion:^(BOOL finished) {
        [view.layer removeAllAnimations];
        [view removeFromSuperview];
        // hide 时动画被打断（finished == NO），此时不能再补碎片，否则永远停不下来
        if (isLoop == YES && finished == YES) {
            [self showLoadingAnimation:icn];
        }
    }];
}
// 创建大小动画（0.8 ↔ 1.0 的呼吸缩放，3s 一程，无限往复）
- (void)createRotationAnimation:(UIImageView *)view value:(CGFloat)value {
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scale.fromValue = @(1.0);
    scale.toValue = @(value);
    scale.duration = 3;
    scale.autoreverses = YES;
    scale.repeatCount = HUGE_VALF;
    scale.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [view.layer addAnimation:scale forKey:@"scaleXY"];
}

// 点击
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint center = [[touches anyObject] locationInView:self];
    [self showLoadingAnimation:nil center:center];
}

#pragma mark - get
- (UIImageView *)icn {
    if (!_icn) {
        _icn = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH / 3, SCREEN_WIDTH / 3)];
        _icn.backgroundColor = [UIColor redColor];
        _icn.frame = CGRectMake((self.width - self.icn.width) / 2,
                                (self.height - self.icn.height) / 2 - 40,
                                self.icn.width,
                                self.icn.height);
        [self addSubview:_icn];
    }
    return _icn;
}
- (UILabel *)nameLab {
    if (!_nameLab) {
        _nameLab = [[UILabel alloc] initWithFrame:CGRectMake(0, self.icn.bottom + 8, SCREEN_WIDTH, 20)];
        _nameLab.font = [UIFont systemFontOfSize:AdjustFont(14) weight:UIFontWeightLight];
        _nameLab.textColor = kColor_Text_Black;
        _nameLab.textAlignment = NSTextAlignmentCenter;
        _nameLab.text = KKLocalized(@"正在请求数据");
        [self addSubview:_nameLab];
    }
    return _nameLab;
}
- (UILabel *)detailLab {
    if (!_detailLab) {
        _detailLab = [[UILabel alloc] initWithFrame:CGRectMake(0, self.nameLab.bottom, SCREEN_WIDTH, 20)];
        _detailLab.font = [UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight];
        _detailLab.textColor = kColor_Text_Gary;
        _detailLab.textAlignment = NSTextAlignmentCenter;
        _detailLab.text = KKLocalized(@"坐下喝口茶, 缓一缓~");
        [self addSubview:_detailLab];
    }
    return _detailLab;
}


@end
