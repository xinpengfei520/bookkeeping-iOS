//
//  SearchViewController.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/2.
//  Copyright © 2022 kk. All rights reserved.
//

#import "SearchViewController.h"
#import "UIViewController+HBD.h"
#import "SearchNavigation.h"

@interface SearchViewController ()

@property (nonatomic, strong) SearchNavigation *navigation;

@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = YES;
    [self navigation];
}

#pragma mark - get
- (SearchNavigation *)navigation {
    if (!_navigation) {
        _navigation = [SearchNavigation loadFirstNib:CGRectMake(0, 0, SCREEN_WIDTH, 110)];
        [self.view addSubview:_navigation];
    }
    return _navigation;
}

@end
