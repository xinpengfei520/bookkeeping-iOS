//
//  SearchNavigation.m (code-only — converted from SearchNavigation.xib)
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/2.
//  Copyright © 2022 kk. All rights reserved.
//

#import "SearchNavigation.h"
#import <Masonry/Masonry.h>

@interface SearchNavigation ()<UITextFieldDelegate>

@end

@implementation SearchNavigation

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
        [self initUI];
    }
    return self;
}

- (void)buildSubviews {
    _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self addSubview:_backBtn];

    _searchTextField = [[UITextField alloc] init];
    [self addSubview:_searchTextField];

    // 原 XIB 的 centerY 是 self.centerY + 24，把内容压在 nav 下半部、给 status bar 留位置
    [_backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_safeAreaLayoutGuideLeft).offset(12);
        make.centerY.equalTo(self).offset(24);
        make.width.height.equalTo(@22);
    }];
    [_searchTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_safeAreaLayoutGuideLeft).offset(48);
        make.right.equalTo(self.mas_safeAreaLayoutGuideRight).offset(-20);
        make.centerY.equalTo(self).offset(24);
        make.height.equalTo(@34);
    }];
}

- (void)initUI {
    [self setBackgroundColor:kColor_Main_Color];
    [self.backBtn setImage:[UIImage imageNamed:@"icon_back_white"] forState:UIControlStateNormal];

    self.searchTextField.placeholder = KKLocalized(@"类别/备注/金额");

    // 圆角胶囊（Spotlight 风格）：自画 cornerRadius + 动态色背景。
    // background 必须随 trait 翻转：textColor 用动态 kColor_Text_Black（dark 模式翻浅灰），
    // 如果 bg 锁死成白色，dark 模式就是浅灰文字叠白底——什么都看不见。
    self.searchTextField.borderStyle = UITextBorderStyleNone;
    self.searchTextField.backgroundColor = KKDynamicColor(
        [UIColor colorWithWhite:1.0 alpha:0.95],
        [UIColor colorWithWhite:0.18 alpha:0.85]
    );
    self.searchTextField.textColor = kColor_Text_Black;
    self.searchTextField.font = [UIFont systemFontOfSize:AdjustFont(14)];
    self.searchTextField.layer.cornerRadius = 17;
    self.searchTextField.layer.masksToBounds = YES;

    // 给左侧 search 图标外面套一层 padding container，避免图标贴住圆角边
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_search_gray.png"]];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.frame = CGRectMake(10, 0, 18, 22);
    UIView *leftPad = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 32, 22)];
    [leftPad addSubview:imageView];
    [self.searchTextField setLeftView:leftPad];
    [self.searchTextField setLeftViewMode:UITextFieldViewModeAlways];
    [self.searchTextField setClearButtonMode:UITextFieldViewModeWhileEditing];
    _searchTextField.returnKeyType = UIReturnKeySearch;
    _searchTextField.delegate = self;

    [self.backBtn addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
        [self routerEventWithName:SEARCH_BACK data:nil];
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [_searchTextField resignFirstResponder];
    [self routerEventWithName:SEARCH_TEXT_INPUT data:textField.text];
    return YES;
}


@end
