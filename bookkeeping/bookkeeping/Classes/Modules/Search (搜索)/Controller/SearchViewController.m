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
#import "SearchList.h"
#import "SearchListSubCell.h"
#import "BookDetailController.h"
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

#pragma mark - request
- (void) searchResultRequest:(NSString*)keyword {
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    [param setValue:keyword forKey:@"keyword"];
    
    [self showProgressHUD:@"搜索中..."];
    @weakify(self)
    [AFNManager POST:bookDetailSearchRequest params:param complete:^(APPResult *result) {
        @strongify(self)
        [self hideHUD];
        if (result.status == HttpStatusSuccess && result.code == BIZ_SUCCESS) {
            NSMutableArray<BookMonthModel *> *bookArray = [BookMonthModel mj_objectArrayWithKeyValuesArray:result.data];
            [self setModels:bookArray];
        } else {
            // 当请求失败时，清空当前显示的列表数据
            [self setModels:nil];
            [self showTextHUD:result.msg delay:1.f];
        }
    }];
}

#pragma mark - set
- (void)setModels:(NSMutableArray<BookMonthModel *> *)models {
    _models = models;
    @weakify(self)
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self)
        self.list.models = models;
    });
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
        };
    }
    return _eventStrategy;
}

- (void)searchTableCellRemove:(SearchListSubCell *)cell {
    
}

- (void)searchWithInputText:(NSString *)input {
    if (!input) {
        [self showTextHUD:@"关键字不能为空" delay:1.f];
        return;
    }
    
    [self searchResultRequest:input];
}

- (void)searchTableCellClick:(BookDetailModel *)model {
    BookDetailController *vc = [[BookDetailController alloc] init];
    vc.model = model;
    [self.navigationController pushViewController:vc animated:true];
}

@end
