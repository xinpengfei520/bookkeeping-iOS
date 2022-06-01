//
//  SearchNavigation.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/2.
//  Copyright © 2022 kk. All rights reserved.
//

#import "SearchNavigation.h"

@implementation SearchNavigation

- (void)initUI {
    [self setBackgroundColor:kColor_Main_Color];
    self.searchTextField.placeholder = @"类别/备注/金额";
    
    UIImageView *imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"icon_search_gray.png"]];
    [self.searchTextField setLeftView:imageView];
    [self.searchTextField setLeftViewMode:UITextFieldViewModeAlways];

}

@end
