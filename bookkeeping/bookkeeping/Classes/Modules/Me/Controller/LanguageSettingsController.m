//
//  LanguageSettingsController.m
//  bookkeeping
//

#import "LanguageSettingsController.h"

#pragma mark - 声明
@interface LanguageSettingsController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<NSDictionary *> *options;

@end


#pragma mark - 实现
@implementation LanguageSettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"语言";
    self.view.backgroundColor = kColor_BG;
    [self.view addSubview:self.tableView];
}

- (NSArray<NSDictionary *> *)options {
    if (!_options) {
        // code = NSNull → "follow system"
        _options = @[
            @{@"title": @"跟随系统", @"code": [NSNull null]},
            @{@"title": @"简体中文", @"code": KKLanguageCodeChinese},
            @{@"title": @"English",  @"code": KKLanguageCodeEnglish},
        ];
    }
    return _options;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = kColor_BG;
        _tableView.separatorInset = UIEdgeInsetsZero;
    }
    return _tableView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.options.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *Id = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Id];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Id];
    }
    NSDictionary *opt = self.options[indexPath.row];
    cell.textLabel.text = opt[@"title"];
    cell.accessoryType = [self isOptionCurrent:opt]
        ? UITableViewCellAccessoryCheckmark
        : UITableViewCellAccessoryNone;
    return cell;
}

- (BOOL)isOptionCurrent:(NSDictionary *)opt {
    NSString *current = [KKI18n userPreferredLanguageCode];
    id code = opt[@"code"];
    if ([code isKindOfClass:[NSNull class]]) {
        return current == nil;
    }
    return [code isKindOfClass:[NSString class]] && [(NSString *)code isEqualToString:current];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return countcoordinatesX(50);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *opt = self.options[indexPath.row];
    if ([self isOptionCurrent:opt]) return;

    id code = opt[@"code"];
    NSString *toSave = [code isKindOfClass:[NSNull class]] ? nil : (NSString *)code;
    [KKI18n setUserPreferredLanguageCode:toSave];
    [tableView reloadData];

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"语言已切换"
        message:@"需要重启 App 后完全生效。"
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"立即重启" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *_) {
        // 0.2s 让 alert dismiss 动画走完，避免 exit(0) 截断动画导致系统警报
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            exit(0);
        });
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"稍后" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
