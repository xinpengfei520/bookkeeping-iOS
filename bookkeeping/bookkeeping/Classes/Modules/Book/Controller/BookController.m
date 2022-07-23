#import "BookController.h"
#import "BKCCollection.h"
#import "BKCNavigation.h"
#import "BKCKeyboard.h"
#import "BKCIncomeModel.h"
#import "KKRefreshGifHeader.h"
#import "BOOK_EVENT.h"
#import "BookDetailModel.h"
#import "MarkCollectionView.h"

#pragma mark - 声明
@interface BookController()<UIScrollViewDelegate>

@property (nonatomic, strong) BKCNavigation *navigation;
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) NSMutableArray<BKCCollection *> *collections;
@property (nonatomic, strong) BKCKeyboard *keyboard;
@property (nonatomic, strong) MarkCollectionView *markView;
@property (nonatomic, strong) NSArray<BKCIncomeModel *> *models;
@property (nonatomic, strong) NSMutableArray<MarkModel *> *markModels;
@property (nonatomic, strong) NSDictionary<NSString *, NSInvocation *> *eventStrategy;

@end


#pragma mark - 实现
@implementation BookController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.hbd_barHidden = YES;
    [self navigation];
    [self scroll];
    [self collections];
    [self keyboard];
    [self markView];
//    [self getCategoryListRequest];
    [self initData];
    
    if (_model) {
        dispatch_async(dispatch_get_main_queue(), ^{
            BKCModel *cmodel = [NSUserDefaults getCategoryModel:self.model.categoryId];
            BOOL is_income = cmodel.is_income;
            [self.scroll setContentOffset:CGPointMake(SCREEN_WIDTH * is_income, 0) animated:false];
            [self.navigation setOffsetX:self.scroll.contentOffset.x];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                BKCCollection *collection = self.collections[is_income];
                NSMutableArray *arrm = [NSMutableArray array];
                if (is_income == false) {
                    [arrm addObjectsFromArray:[NSUserDefaults objectForKey:PIN_CATE_SYS_HAS_PAY]];
                    [arrm addObjectsFromArray:[NSUserDefaults objectForKey:PIN_CATE_CUS_HAS_PAY]];
                } else {
                    [arrm addObjectsFromArray:[NSUserDefaults objectForKey:PIN_CATE_SYS_HAS_INCOME]];
                    [arrm addObjectsFromArray:[NSUserDefaults objectForKey:PIN_CATE_CUS_HAS_INCOME]];
                }
                [collection setSelectIndex:[NSIndexPath indexPathForRow:[arrm indexOfObject:cmodel] inSection:0]];
                [collection reloadData];
                [self bookClickItem:collection];
                [self.keyboard setModel:self.model];
            });
        });
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    
    [self getBookMarkListRequest];
}

- (void)initData{
    BKCIncomeModel *model1 = [[BKCIncomeModel alloc] init];
    model1.is_income = false;
    model1.list = ({
        NSMutableArray<BKCModel *> *sysHasPayArr = [NSUserDefaults objectForKey:PIN_CATE_SYS_HAS_PAY];
        NSMutableArray<BKCModel *> *cusHasPayArr = [NSUserDefaults objectForKey:PIN_CATE_CUS_HAS_PAY];
        NSMutableArray<BKCModel *> *payArr = ({
            NSMutableArray *arrm = [NSMutableArray arrayWithArray:sysHasPayArr];
            [arrm addObjectsFromArray:cusHasPayArr];
            arrm = [BKCModel mj_objectArrayWithKeyValuesArray:arrm];
            arrm;
        });
        payArr;
    });
    
    BKCIncomeModel *model2 = [[BKCIncomeModel alloc] init];
    model2.is_income = true;
    model2.list = ({
        NSMutableArray<BKCModel *> *sysHasIncomeArr = [NSUserDefaults objectForKey:PIN_CATE_SYS_HAS_INCOME];
        NSMutableArray<BKCModel *> *cusHasIncomeArr = [NSUserDefaults objectForKey:PIN_CATE_CUS_HAS_INCOME];
        NSMutableArray<BKCModel *> *incomeArr = ({
            NSMutableArray *arrm = [NSMutableArray arrayWithArray:sysHasIncomeArr];
            [arrm addObjectsFromArray:cusHasIncomeArr];
            arrm = [BKCModel mj_objectArrayWithKeyValuesArray:arrm];
            arrm;
        });
        incomeArr;
    });
    [self setModels:@[model1, model2]];
}


#pragma mark - request
// 获取我的分类
- (void)getCategoryListRequest {
    @weakify(self)
    [self.scroll createRequest:CategoryListRequest params:@{} complete:^(APPResult *result) {
        @strongify(self)
        [self setModels:[BKCIncomeModel mj_objectArrayWithKeyValuesArray:result.data]];
    }];
}

- (void)getBookMarkListRequest {
    @weakify(self)
    [self.scroll createRequest:bookMarkListRequest params:@{} complete:^(APPResult *result) {
        @strongify(self)
        if (result.status == HttpStatusSuccess && result.code == BIZ_SUCCESS) {
            [self setMarkModels:[MarkModel mj_objectArrayWithKeyValuesArray:result.data]];
        } else {
            [self showTextHUD:result.msg delay:1.f];
        }
    }];
}

// 记账
- (void)createBookRequest:(NSString *)price mark:(NSString *)mark date:(NSDate *)date {
    NSInteger index = self.scroll.contentOffset.x / SCREEN_WIDTH;
    BKCCollection *collection = self.collections[index];
    BKCModel *cmodel = collection.model.list[collection.selectIndex.row];
    
    BookDetailModel *model = [[BookDetailModel alloc] init];
    model.bookId = [[BookDetailModel getBookId] integerValue];
    model.price = [[NSDecimalNumber decimalNumberWithString:price] doubleValue];
    model.year = date.year;
    model.month = date.month;
    model.day = date.day;
    // 去掉备注中的空格并判空，如果为空则使用类别名作为备注
    model.mark = ([allTrim(mark)length] == 0)?cmodel.name:mark;
    model.categoryId = cmodel.Id;
    
    // 新增
    if (!_model) {
        //[NSUserDefaults insertBookModel:model];
    }
    // 修改
    else {
        _model.price = [price floatValue];
        _model.year = date.year;
        _model.month = date.month;
        _model.day = date.day;
        _model.mark = mark;
        _model.categoryId = cmodel.Id;
        model = _model;
    }
    
    // 编辑修改完成
    if (self.navigationController.viewControllers.count != 1) {
        [self.navigationController popViewControllerAnimated:true];
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_BOOK_UPDATE object:model];
    } else {
        // 记账完成
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_BOOK_ADD object:model];
        }];
    }
}


#pragma mark - set
- (void)setModels:(NSArray<BKCIncomeModel *> *)models {
    _models = models;
    for (int i=0; i<models.count; i++) {
        self.collections[i].model = models[i];
    }
}

- (void)setMarkModels:(NSMutableArray<MarkModel *> *)models {
    _markModels = models;
    self.markView.models = models;
}


#pragma mark - 事件
- (void)routerEventWithName:(NSString *)eventName data:(id)data {
    [self handleEventWithName:eventName data:data];
}

- (void)handleEventWithName:(NSString *)eventName data:(id)data {
    NSInvocation *invocation = self.eventStrategy[eventName];
    [invocation setArgument:&data atIndex:2];
    [invocation invoke];
    [super routerEventWithName:eventName data:data];
}

// 点击导航栏
- (void)bookClickNavigation:(NSNumber *)index {
    [self.scroll setContentOffset:CGPointMake(SCREEN_WIDTH * [index integerValue], 0) animated:YES];
}

- (void)bookItemSelect:(id *)data {
    NSInteger index = self.scroll.contentOffset.x / SCREEN_WIDTH;
    BKCCollection *collection = self.collections[index];
    BKCModel *cmodel = collection.model.list[collection.selectIndex.row];
    NSInteger categoryId = cmodel.Id;
    
    // 根据 categoryId 过滤
    NSString *preStr = [NSString stringWithFormat:@"categoryId == %ld", categoryId];
    NSMutableArray<MarkModel *> *models = [NSMutableArray kk_filteredArrayUsingStringFormat:preStr array:_markModels];
    
    // 根据 frequency 倒叙排序
    models = [NSMutableArray arrayWithArray:[models sortedArrayUsingComparator:^NSComparisonResult(MarkModel *obj1, MarkModel *obj2) {
        return obj2.frequency - obj1.frequency;
    }]];
    self.markView.models = models;
}

// 点击item
- (void)bookClickItem:(BKCCollection *)collection {
    NSIndexPath *indexPath = collection.selectIndex;
    BKCIncomeModel *listModel = _models[collection.tag];
    // 选择类别
    if (indexPath.row != (listModel.list.count - 1)) {
        // 显示键盘
        [self.keyboard show];
        // 刷新
        NSInteger page = _scroll.contentOffset.x / SCREEN_WIDTH;
        BKCCollection *collection = self.collections[page];
        [collection setHeight:SCREEN_HEIGHT - NavigationBarHeight - self.keyboard.height];
        [collection scrollToIndex:indexPath];
    }
    // 设置
    else {
        // 隐藏键盘
        for (BKCCollection *collection in self.collections) {
            [collection reloadSelectIndex];
            [collection setHeight:SCREEN_HEIGHT - NavigationBarHeight];
        }
        [self.keyboard hide];
        // 刷新
        CAController *vc = [[CAController alloc] init];
        [vc setIs_income:collection.tag];
        [vc setComplete:^{
            [self initData];
        }];
        [self.navigationController pushViewController:vc animated:YES];
    }
}


#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    for (BKCCollection *collection in self.collections) {
        [collection reloadSelectIndex];
        [collection setHeight:SCREEN_HEIGHT - NavigationBarHeight];
    }
    [self.keyboard hide];
    [self.navigation setOffsetX:scrollView.contentOffset.x];
}


#pragma mark - get
- (UIScrollView *)scroll {
    if (!_scroll) {
        _scroll = [[UIScrollView alloc] initWithFrame:({
            CGFloat left = 0;
            CGFloat top = NavigationBarHeight;
            CGFloat width = SCREEN_WIDTH;
            CGFloat height = SCREEN_HEIGHT - NavigationBarHeight;
            CGRectMake(left, top, width, height);
        })];
        [_scroll setDelegate:self];
        [_scroll setShowsHorizontalScrollIndicator:NO];
        [_scroll setPagingEnabled:YES];
        [self.view addSubview:_scroll];
    }
    return _scroll;
}

- (BKCNavigation *)navigation {
    if (!_navigation) {
        _navigation = [BKCNavigation loadFirstNib:CGRectMake(0, 0, SCREEN_WIDTH, NavigationBarHeight)];
        [self.view addSubview:_navigation];
    }
    return _navigation;
}

- (NSMutableArray<BKCCollection *> *)collections {
    if (!_collections) {
        _collections = [NSMutableArray array];
        for (int i=0; i<2; i++) {
            BKCCollection *collection = [BKCCollection initWithFrame:({
                CGFloat width = SCREEN_WIDTH;
                CGFloat left = i * width;
                CGFloat height = SCREEN_HEIGHT - NavigationBarHeight;
                CGRectMake(left, 0, width, height);
            })];
            [collection setTag:i];
            [_scroll setContentSize:CGSizeMake(SCREEN_WIDTH * 2, 0)];
            [_scroll addSubview:collection];
            [_collections addObject:collection];
        }
    }
    return _collections;
}

- (BKCKeyboard *)keyboard {
    if (!_keyboard) {
        @weakify(self)
        _keyboard = [BKCKeyboard init];
        [_keyboard setComplete:^(NSString *price, NSString *mark, NSDate *date) {
            @strongify(self)
            [self createBookRequest:price mark:mark date:date];
        }];
        [self.view addSubview:_keyboard];
    }
    return _keyboard;
}

- (MarkCollectionView *)markView {
    if (!_markView) {
        @weakify(self)
        _markView = [MarkCollectionView initWithFrame:({
            CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, countcoordinatesX(44));
        })];
        [_markView setComplete:^(MarkModel *model) {
            @strongify(self)
            [self.keyboard setMark:model];
        }];
        [self.view addSubview:_markView];
    }
    return _markView;
}

- (NSDictionary<NSString *, NSInvocation *> *)eventStrategy {
    if (!_eventStrategy) {
        _eventStrategy = @{
            BOOK_CLICK_ITEM: [self createInvocationWithSelector:@selector(bookClickItem:)],
            BOOK_ITEM_SELECT: [self createInvocationWithSelector:@selector(bookItemSelect:)],
            BOOK_CLICK_NAVIGATION: [self createInvocationWithSelector:@selector(bookClickNavigation:)],
        };
    }
    return _eventStrategy;
}

#pragma mark - 系统键盘通知
- (void)showKeyboard:(NSNotification *)not {
    NSTimeInterval time = [not.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGFloat keyHeight = [not.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    [UIView animateWithDuration:time delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.markView show:keyHeight];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)hideKeyboard:(NSNotification *)not {
    NSTimeInterval time = [not.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    [UIView animateWithDuration:time delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.markView hide];
    } completion:^(BOOL finished) {
        
    }];
}


#pragma mark - 系统
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
