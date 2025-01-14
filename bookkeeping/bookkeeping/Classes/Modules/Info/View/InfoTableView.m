/**
 * 列表
 * @author 郑业强 2018-12-22 创建文件
 */

#import "InfoTableView.h"
#import "InfoTableCell.h"
#import "InfoFooter.h"
#import "InfoTableDataSource.h"

#pragma mark - 声明
@interface InfoTableView()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray<NSArray<NSString *> *> *arr;
@property (nonatomic, strong) InfoFooter *footer;

@end


#pragma mark - 实现
@implementation InfoTableView


- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    if (self = [super initWithFrame:frame style:style]) {
        self.delegate = self;
        self.dataSource = self;
        self.backgroundColor = kColor_Line_Color;
        self.contentInset = UIEdgeInsetsMake(countcoordinatesX(10), 0, 0, 0);
        self.separatorColor = kColor_BG;
        [self lineAll];
        [self lineHide];
    }
    return self;
}


#pragma mark - set
- (void)setModel:(UserModel *)model {
    _model = model;
    [self reloadData];
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_model && _model.userId) {
        return self.arr.count;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < self.arr.count) {
        return self.arr[section].count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    InfoTableCell *cell = [InfoTableCell loadFirstNib:tableView];
    cell.indexPath = indexPath;
    cell.model = _model;
    return cell;
}


#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return countcoordinatesX(50);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self routerEventWithName:INFO_CELL_CLICK data:indexPath];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (!_model || !_model.userId) {
        return [UIView new];
    }
    
    if (section == 0) {
        return [UIView new];
    } else if (section == self.arr.count - 1) {
        // 最后一个 section 显示退出登录按钮
        return [self footer];
    } else {
        // 中间的 section 显示分隔线
        UIView *lineView = [[UIView alloc] init];
        lineView.backgroundColor = kColor_Line_Color;
        return lineView;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (!_model || !_model.userId) {
        return 0;
    }
    
    if (section == 0) {
        return countcoordinatesX(10);
    } else if (section == self.arr.count - 1) {
        return countcoordinatesX(60);
    } else {
        return 1.0f;  // 分隔线高度
    }
}


#pragma mark - get
- (NSArray<NSArray<NSString *> *> *)arr {
    if (!_arr) {
        _arr = [InfoTableDataSource getInfoTableData];
    }
    return _arr;
}

- (InfoFooter *)footer {
    if (!_footer) {
        _footer = [InfoFooter loadFirstNib:CGRectMake(0, 0, SCREEN_WIDTH, countcoordinatesX(60))];
    }
    return _footer;
}


@end
