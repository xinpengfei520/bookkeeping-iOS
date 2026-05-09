/**
 * 账单
 * @author 郑业强 2019-01-09 创建文件
 */

#import "BillController.h"
#import "BillTable.h"
#import "BookDetailModel.h"

#pragma mark - 声明
@interface BillController()

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) BillTable *table;

@end


#pragma mark - 实现
@implementation BillController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = KKLocalized(@"账单");
    [self setDate:[NSDate date]];
    {
        // Composite year + arrow as the only customView right bar item — wrapped
        // in a plain UIView so the year label keeps its tag-10 lookup contract.
        NSDate *date = [NSDate date];
        NSString *year = [NSString stringWithFormat:KKLocalized(@"%ld年"), date.year];
        UIFont *font = [UIFont fontWithName:@"Helvetica Neue" size:AdjustFont(14)];
        CGFloat labWidth = [year sizeWithMaxSize:CGSizeMake(MAXFLOAT, 0) font:font].width;
        CGFloat arrowWidth = 10;
        CGFloat totalWidth = labWidth + arrowWidth + 4;

        UIView *wrapper = [[UIView alloc] initWithFrame:CGRectMake(0, 0, totalWidth, 44)];

        UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, labWidth, 44)];
        lab.text = year;
        lab.font = font;
        lab.textColor = kColor_Text_White;
        lab.textAlignment = NSTextAlignmentRight;
        lab.tag = 10;
        [wrapper addSubview:lab];

        UIImageView *arrow = [[UIImageView alloc] initWithFrame:CGRectMake(totalWidth - arrowWidth, 0, arrowWidth, 44)];
        arrow.image = [UIImage imageNamed:@"time_down"];
        arrow.contentMode = UIViewContentModeScaleAspectFit;
        [wrapper addSubview:arrow];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(rightButtonClick)];
        [wrapper addGestureRecognizer:tap];

        self.navigationItem.rightBarButtonItem =
            [[UIBarButtonItem alloc] initWithCustomView:wrapper];
    }
    [self table];
    dispatch_async(dispatch_get_main_queue(), ^{
       [self updateYearValue:[@(self.date.year) description]];
    });
}

- (void)rightButtonClick {
    @weakify(self)
    NSDate *date = [NSDate date];
    NSDate *min = [NSDate br_setYear:2000 month:1 day:1];
    NSDate *max = [NSDate br_setYear:date.year + 3 month:12 day:31];
    
    // 1.创建日期选择器
    BRDatePickerView *datePickerView = [[BRDatePickerView alloc]init];
    // 2.设置属性
    datePickerView.pickerMode = BRDatePickerModeY;
    datePickerView.title = KKLocalized(@"选择日期");
    datePickerView.selectDate = self.date;
    datePickerView.minDate = min;
    datePickerView.maxDate = max;
    datePickerView.isAutoSelect = false;
    datePickerView.resultBlock = ^(NSDate *selectDate, NSString *selectValue) {
        NSLog(@"选择的值：%@", selectValue);
        @strongify(self)
        [self updateYearValue:selectValue];
    };
    
    // 3.显示
    [datePickerView show];
}

- (void)updateYearValue:(NSString *)selectValue {
    [self setDate:[NSDate dateWithYMD:[NSString stringWithFormat:@"%@-01-01", selectValue]]];
    [(UILabel *)[self.navigationItem.rightBarButtonItem.customView viewWithTag:10]
        setText:[NSString stringWithFormat:KKLocalized(@"%ld年"), self.date.year]];
    [self updateData];
}

- (void)updateData{
    NSMutableArray<BookDetailModel *> *bookArr = [NSUserDefaults objectForKey:All_BOOK_LIST];
    
    NSString *predicate = [NSString stringWithFormat:@"year == %ld AND categoryId >= 33",self.date.year];
    NSMutableArray<BookDetailModel *> *incomeArr = [NSMutableArray kk_filteredArrayUsingStringFormat:predicate array:bookArr];
    
    predicate = [NSString stringWithFormat:@"year == %ld AND categoryId <= 32",self.date.year];
    NSMutableArray<BookDetailModel *> *payArr = [NSMutableArray kk_filteredArrayUsingStringFormat:predicate array:bookArr];
    
    [self.table setIncome:[[incomeArr valueForKeyPath:@"@sum.price.floatValue"] floatValue]];
    [self.table setPay:[[payArr valueForKeyPath:@"@sum.price.floatValue"] floatValue]];
    
    NSMutableArray *arrm = [NSMutableArray array];
    
    for (NSInteger i=1; i<=12; i++) {
        NSString *incomeStr = [NSString stringWithFormat:@"year == %ld AND month == %ld AND categoryId >= 33", self.date.year,i];
        NSMutableArray<BookDetailModel *> *incomeModels = [NSMutableArray kk_filteredArrayUsingStringFormat:incomeStr array:bookArr];
        
        NSString *payStr = [NSString stringWithFormat:@"year == %ld AND month == %ld AND categoryId <= 32",self.date.year,i];
        NSMutableArray<BookDetailModel *> *payModels = [NSMutableArray kk_filteredArrayUsingStringFormat:payStr array:bookArr];
        
        CGFloat income = [[incomeModels valueForKeyPath:@"@sum.price.floatValue"] floatValue];
        CGFloat pay = [[payModels valueForKeyPath:@"@sum.price.floatValue"] floatValue];
        
        NSDictionary *param = @{@"month": [NSString stringWithFormat:KKLocalized(@"%ld月"), i],
                                @"income": [NSString stringWithFormat:@"%.2f", income],
                                @"pay": [NSString stringWithFormat:@"%.2f", pay],
                                @"sum": [NSString stringWithFormat:@"%.2f", income - pay]
        };
        [arrm addObject:param];
    }
    
    BOOL maxMonth = false;
    NSMutableArray *newArrm = [NSMutableArray array];
    for (NSInteger i=12; i>=1; i--) {
        NSDictionary *param = arrm[i-1];
        if (![param[@"income"] isEqualToString:@"0.00"] || ![param[@"pay"] isEqualToString:@"0.00"]) {
            maxMonth = true;
        }
        if (maxMonth == true) {
            [newArrm addObject:param];
        }
    }
    [self.table setModels:newArrm];
}


#pragma mark - get
- (BillTable *)table {
    if (!_table) {
        _table = [[BillTable alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - NavigationBarHeight) style:UITableViewStyleGrouped];
        [_table setBackgroundView:({
            UIView *back = [[UIView alloc] initWithFrame:self.table.bounds];
            [back setBackgroundColor:kColor_BG];
            [back addSubview:({
                UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 120)];
                view.backgroundColor = kColor_Main_Color;
                view;
            })];
            back;
        })];
        [self.view addSubview:_table];
    }
    return _table;
}


@end
