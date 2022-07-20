//
//  SearchViewController.m
//  bookkeeping
//
//  Created by PengfeiXin on 2022/6/2.
//  Copyright © 2022 kk. All rights reserved.
//

#import "SearchViewController.h"
#import "SearchNavigation.h"
#import "SearchList.h"
#import "SearchListSubCell.h"
#import "SEARCH_EVENT.h"

@interface SearchViewController ()

@property (nonatomic, strong) SearchNavigation *navigation;
@property (nonatomic, strong) SearchList *list;
@property (nonatomic, strong) NSMutableArray<BookMonthModel *> *models;
@property (nonatomic, strong) NSDictionary<NSString *, NSInvocation *> *eventStrategy;

@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = YES;
    [self navigation];
    [self list];
    [_navigation.searchTextField becomeFirstResponder];
}

#pragma mark - get
- (SearchNavigation *)navigation {
    if (!_navigation) {
        _navigation = [SearchNavigation loadFirstNib:CGRectMake(0, 0, SCREEN_WIDTH, 110)];
        [self.view addSubview:_navigation];
    }
    return _navigation;
}

- (SearchList *)list {
    if (!_list) {
        _list = [SearchList loadCode:({
            CGFloat top = CGRectGetMaxY(_navigation.frame);
            CGFloat height = SCREEN_HEIGHT - top;
            CGRectMake(0, top, SCREEN_WIDTH, height);
        })];
        [self.view addSubview:_list];
    }
    return _list;
}

#pragma mark - set
- (void)setModels:(NSMutableArray<BookMonthModel *> *)models {
    _models = models;
    self.list.models = models;
}

#pragma mark - event
- (void)routerEventWithName:(NSString *)eventName data:(id)data {
    [self handleEventWithName:eventName data:data];
}

- (void)handleEventWithName:(NSString *)eventName data:(id)data {
    NSInvocation *invocation = self.eventStrategy[eventName];
    [invocation setArgument:&data atIndex:2];
    [invocation invoke];
    [super routerEventWithName:eventName data:data];
}

- (NSDictionary<NSString *, NSInvocation *> *)eventStrategy {
    if (!_eventStrategy) {
        _eventStrategy = @{
            SEARCH_CELL_REMOVE: [self createInvocationWithSelector:@selector(searchTableCellRemove:)],
            SEARCH_CELL_CLICK: [self createInvocationWithSelector:@selector(searchTableCellClick:)],
            SEARCH_TEXT_INPUT: [self createInvocationWithSelector:@selector(searchWithInputText:)],
            SEARCH_BACK: [self createInvocationWithSelector:@selector(backAction:)],
        };
    }
    return _eventStrategy;
}

- (void)backAction:(id)data {
    [self.navigationController popViewControllerAnimated:true];
}

- (void)searchTableCellRemove:(SearchListSubCell *)cell {
    
}

- (void)searchWithInputText:(NSString *)input {
    if ([allTrim(input)length] == 0) {
        [self showTextHUD:@"关键字不能为空" delay:1.f];
        return;
    }
    
    NSMutableArray<BookMonthModel *> *list = [BookMonthModel searchWithKeyword:input];
    if (list && list.count > 0) {
        [self setModels:list];
    }else {
        [self setModels:nil];
    }
}

- (void)searchTableCellClick:(BookDetailModel *)model {
    BookDetailController *vc = [[BookDetailController alloc] init];
    vc.model = model;
    [self.navigationController pushViewController:vc animated:true];
}

@end
