//
//  SettingsController.m
//  bookkeeping
//

#import "SettingsController.h"
#import "MineTableCell.h"
#import "LAContextManager.h"
#import <Masonry/Masonry.h>

#pragma mark - 声明
@interface SettingsController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *table;
@property (nonatomic, copy) NSArray<NSDictionary *> *rows;

@end


#pragma mark - 实现
@implementation SettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = KKLocalized(@"设置");
    self.view.backgroundColor = kColor_BG;

    [self.view addSubview:self.table];
    [_table mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}


#pragma mark - data

// 行结构 — title / 资源图标名 (或 "sf:xxx" 走 SF Symbol) / status (用于
// MineTableCell.status，1 表示带 switch；其它用于 hint 风格扩展)
- (NSArray<NSDictionary *> *)rows {
    if (!_rows) {
        _rows = @[
            @{@"title": KKLocalized(@"类别设置"), @"icon": @"mine_category",  @"status": @0},
            @{@"title": KKLocalized(@"定时提醒"), @"icon": @"mine_remind",    @"status": @0},
            @{@"title": KKLocalized(@"面容解锁"), @"icon": @"mine_face_id",   @"status": @1},
            @{@"title": KKLocalized(@"导出数据"), @"icon": @"mine_export",    @"status": @0},
            @{@"title": KKLocalized(@"语言"),     @"icon": @"sf:globe",       @"status": @0},
            @{@"title": KKLocalized(@"深色模式"), @"icon": @"sf:moon.fill",   @"status": @0},
        ];
    }
    return _rows;
}


- (UITableView *)table {
    if (!_table) {
        _table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _table.delegate = self;
        _table.dataSource = self;
        _table.backgroundColor = kColor_BG;
        _table.showsVerticalScrollIndicator = NO;
        _table.separatorInset = UIEdgeInsetsZero;
    }
    return _table;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MineTableCell *cell = [MineTableCell loadFirstNib:tableView];
    cell.indexPath = indexPath;
    NSDictionary *row = self.rows[indexPath.row];
    cell.nameLab.text = row[@"title"];

    NSString *iconName = row[@"icon"];
    if ([iconName hasPrefix:@"sf:"]) {
        UIImageSymbolConfiguration *cfg =
            [UIImageSymbolConfiguration configurationWithPointSize:22
                                                            weight:UIImageSymbolWeightRegular];
        UIImage *symbol = [[UIImage systemImageNamed:[iconName substringFromIndex:3]
                                       withConfiguration:cfg]
                           imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.icon.image = symbol;
        cell.icon.tintColor = kColor_Main_Color;
    } else {
        cell.icon.image = [UIImage imageNamed:iconName];
    }
    cell.status = [row[@"status"] integerValue];
    cell.detailLab.hidden = YES;

    // Face ID 行（row==2）：恢复 switch 状态 + 绑定 valueChanged
    if (indexPath.row == 2) {
        NSNumber *faceId = [NSUserDefaults objectForKey:PIN_SETTING_FACE_ID];
        [cell.sw setOn:[faceId boolValue]];
        [cell.sw removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
        [cell.sw addTarget:self action:@selector(faceIDSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return cell;
}

- (void)faceIDSwitchChanged:(UISwitch *)sw {
    // 老 Mine 流程的 contract：toggle 后必须先过 LAContext 验证才真正持久化。
    // 防止设备没有 biometrics 的时候被误开 face id 锁，下次启动陷入死循环。
    // 这一步在 1.0.7 重构 SettingsController 时漏了，导致用户报告"开关
    // 打开但是没有起作用" —— 因为没有验证步骤把开关行为闭环。
    BOOL targetValue = sw.on;
    [LAContextManager callLAContextManagerWithController:self success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSUserDefaults setObject:@(targetValue) forKey:PIN_SETTING_FACE_ID];
        });
    } failure:^(NSError *tyError, LAContextErrorType feedType) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 验证失败 / 用户取消 → 撤回 switch UI
            [sw setOn:!targetValue animated:YES];
        });
    }];
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return countcoordinatesX(50);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return countcoordinatesX(10);
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [UIView new];
    view.backgroundColor = kColor_BG;
    return view;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0: {
            CAController *vc = [[CAController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case 1: {
            TimeRemindController *vc = [[TimeRemindController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        // case 2: 面容解锁 - 由 cell.sw valueChanged 处理，点击 cell 不导航
        case 3: {
            ExportController *vc = [[ExportController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case 4: {
            LanguageSettingsController *vc = [[LanguageSettingsController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case 5: {
            ThemeSettingsController *vc = [[ThemeSettingsController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        default: break;
    }
}


@end
