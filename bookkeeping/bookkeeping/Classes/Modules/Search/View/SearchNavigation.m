//
//  SearchNavigation.m
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

- (void)initUI {
	[self setBackgroundColor:kColor_Main_Color];
	self.searchTextField.placeholder = KKLocalized(@"类别/备注/金额");

    // 圆角胶囊（Spotlight 风格）：XIB 的 borderStyle=roundedRect 系统边框在 iOS 16+
    // 渲染极弱、视觉上几乎看不出圆角。关掉系统 border 自画 cornerRadius + 半透明白底。
    // 去掉 border 后 textfield 的 intrinsic 高度会塌缩，显式补一个 height 约束。
    self.searchTextField.borderStyle = UITextBorderStyleNone;
    self.searchTextField.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.95];
    self.searchTextField.textColor = kColor_Text_Black;
    self.searchTextField.font = [UIFont systemFontOfSize:AdjustFont(14)];
    self.searchTextField.layer.cornerRadius = 17;
    self.searchTextField.layer.masksToBounds = YES;
    [self.searchTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@34);
    }];

    // 给左侧 search 图标外面套一层 padding container，避免图标贴住圆角边
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_search_gray.png"]];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.frame = CGRectMake(10, 0, 18, 22);
    UIView *leftPad = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 32, 22)];
    [leftPad addSubview:imageView];
    [self.searchTextField setLeftView:leftPad];
	[self.searchTextField setLeftViewMode:UITextFieldViewModeAlways];
	[self.searchTextField setClearButtonMode:UITextFieldViewModeWhileEditing];
    // 变为搜索按钮
	_searchTextField.returnKeyType = UIReturnKeySearch;
    // 设置代理
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
