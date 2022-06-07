//
//  SearchNavigation.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/2.
//  Copyright © 2022 kk. All rights reserved.
//

#import "SearchNavigation.h"

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
	_searchTextField.returnKeyType = UIReturnKeySearch;//变为搜索按钮
	_searchTextField.delegate = self;//设置代理
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	NSLog(@"点击了搜索");
    [_searchTextField isFirstResponder:NO]
	return YES;
}


@end
