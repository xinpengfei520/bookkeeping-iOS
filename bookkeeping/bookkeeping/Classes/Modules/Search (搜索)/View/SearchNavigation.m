//
//  SearchNavigation.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/2.
//  Copyright © 2022 kk. All rights reserved.
//

#import "SearchNavigation.h"
#import "SEARCH_EVENT.h"

@interface SearchNavigation ()<UITextFieldDelegate>

@end

@implementation SearchNavigation

- (void)initUI {
	[self setBackgroundColor:kColor_Main_Color];
	self.searchTextField.placeholder = @"类别/备注/金额";

	UIImageView *imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"icon_search_gray.png"]];
	[self.searchTextField setLeftView:imageView];
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
