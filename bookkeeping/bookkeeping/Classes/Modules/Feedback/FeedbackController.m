//
//  FeedbackController.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/7/7.
//  Copyright © 2022 kk. All rights reserved.
//

#import "FeedbackController.h"

@interface FeedbackController ()<UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *textField;

@end

@implementation FeedbackController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = NO;
    self.hbd_barTintColor = kColor_Main_Color;
    [self setNavTitle:@"反馈"];
    [self textField];
    [self.textField becomeFirstResponder];
}

- (UITextField *)textField {
    if (!_textField) {
        CGFloat padding = 16;
        _textField = [[UITextField alloc]initWithFrame:CGRectMake(padding,0,SCREEN_WIDTH-padding*2, countcoordinatesX(64))];
        _textField.backgroundColor = [UIColor whiteColor];
        _textField.placeholder = @"请输入您的问题";
        [self.textField setClearButtonMode:UITextFieldViewModeWhileEditing];
        // 变为发送按钮
        _textField.returnKeyType = UIReturnKeySend;
        // 设置代理
        _textField.delegate = self;
        [self.view addSubview:_textField];
    }
    return _textField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [_textField resignFirstResponder];
    //[self routerEventWithName:SEARCH_TEXT_INPUT data:textField.text];
    return YES;
}

@end
