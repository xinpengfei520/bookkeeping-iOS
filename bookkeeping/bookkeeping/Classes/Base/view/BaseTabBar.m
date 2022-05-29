//
//  BaseTabBar.m
//  weibo-OC
//
//  Created by Oboe_b on 16/8/29.
//  Copyright © 2016年 Oboe_b. All rights reserved.
//

#import "BaseTabBar.h"
#import "UIView+BorderLine.h"

@interface BaseTabBar ()

@property (strong, nonatomic) UIButton *composeButton;
@property (nonatomic, strong) NSMutableArray *views;

@end

@implementation BaseTabBar


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self setBackgroundColor:kColor_White];
    [self setShadowLine:[kColor_Text_Gary colorWithAlphaComponent:0.1]];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self views];
    
    for (id obj in self.subviews) {
        if ([obj isKindOfClass:NSClassFromString(@"UITabBarButton")]) {
            [(UIView *)obj setAlpha:0];
            [(UIView *)obj setUserInteractionEnabled:NO];
        }
    }
}

- (void)click:(NSInteger)index {
    NSArray<NSArray *> *image = @[
        @[@"tabbar_detail_n",
          @"tabbar_add_n"
        ],
        @[@"tabbar_detail_s",
          @"tabbar_add_h"
        ]
    ];
    
    for (int y=0; y<self.views.count; y++) {
        UIView *subview = self.views[y];
        UIImageView *subicon = [subview viewWithTag:10];
        subicon.image = [UIImage imageNamed:y == index ? image[1][y] : image[0][y]];
    }
}

// 此方法的作用是增大记账按钮的点击区域，因为记账按钮更大一些，记账按钮的下标为1，所以使用 self.views[1]
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    
    CGPoint newPoint = [self convertPoint:point toView:self.views[1]];
    UIImageView *image = [self.views[1] viewWithTag:10];

    if (CGRectContainsPoint(image.frame, newPoint)) {
        // tabbar 显示中
        id obj = [UIApplication sharedApplication].keyWindow.rootViewController;
        if ([obj isKindOfClass:[BaseTabBarController class]]) {
            BaseTabBarController *tab = (BaseTabBarController *)obj;
            BaseNavigationController *nav = tab.viewControllers[tab.selectedIndex];
            if (nav.viewControllers.count == 1) {
                return self.views[1];
            }
        }
    }
    
    return view;
}


#pragma mark - 点击
- (void)setIndex:(NSInteger)index {
    _index = index;
    [self click:index];
}


#pragma mark - set
- (void)setShadowLine:(UIColor *)color {
    // 改变tabbar 线条颜色
    [self setShadowImage:({
        CGRect rect = CGRectMake(0, 0, SCREEN_WIDTH, 1);
        UIGraphicsBeginImageContext(rect.size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextFillRect(context, rect);
        UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        img;
    })];
    [self setBackgroundImage:[[UIImage alloc] init]];
}


#pragma mark - get
- (NSMutableArray *)views {
    if (!_views) {
        _views = [[NSMutableArray alloc] init];
        
        NSArray<NSArray *> *image = @[
            @[@"tabbar_detail_n",
              @"tabbar_add_n"
            ],
            @[@"tabbar_detail_s",
              @"tabbar_add_h"
            ]
        ];
        
        NSInteger current = 0;
        NSInteger count = [image[0] count];
        
        for (int i=0; i<count; i++) {
            CGFloat width = SCREEN_WIDTH / count;
            // tab 文字上面的 icon
            UIImageView *icon = ({
                UIImageView *icon = [[UIImageView alloc] initWithFrame:({
                    CGRect frame;
                    if (i != 1) {
                        frame = CGRectMake((width - 23) / 2, 7, 23, 23);
                    }
                    else {
                        frame = CGRectMake(0, 0, width, 60);
                    }
                    frame;
                })];
                icon.image = [UIImage imageNamed:current == i ? image[1][i] : image[0][i]];
                icon.contentMode = UIViewContentModeScaleAspectFit;
                icon.tag = 10;
                icon;
            });
            
            UIView *item = ({
                UIView *item = [[UIView alloc] initWithFrame:({
                    CGFloat left = width * i;
                    CGRect frame;
                    if (i != 1) {
                        frame = CGRectMake(left, 0, width, TabbarHeight);
                    }
                    else {
                        frame = CGRectMake(left, -30, width, TabbarHeight + 30);
                    }
                    frame;
                })];
                [item addSubview:icon];
                item;
            });
            
            [self addSubview:item];
            [_views addObject:item];
            
            __weak typeof(self) weak = self;
            [item addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
                if (weak.click) {
                    weak.click(i);
                }
            }];
        }
    }
    
    return _views;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
