//
//  AssetsController.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/7/7.
//  Copyright © 2022 kk. All rights reserved.
//

#import "AssetsController.h"
#import "UIViewController+HBD.h"


@interface AssetsController ()

@end

@implementation AssetsController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = NO;
    self.hbd_barTintColor = kColor_Main_Color;
    [self setNavTitle:@"资产"];
}


@end
