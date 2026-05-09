//
//  ThemeSettingsController.m
//  bookkeeping
//

#import "ThemeSettingsController.h"
#import "KKTheme.h"

#pragma mark - 声明
@interface ThemeSettingsController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<NSDictionary *> *options;

@end


#pragma mark - 实现
@implementation ThemeSettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = KKLocalized(@"深色模式");
    self.view.backgroundColor = kColor_BG;
    [self.view addSubview:self.tableView];
}

- (NSArray<NSDictionary *> *)options {
    if (!_options) {
        _options = @[
            @{@"title": KKLocalized(@"跟随系统"), @"mode": [NSNull null]},
            @{@"title": KKLocalized(@"浅色"),     @"mode": KKThemeModeLight},
            @{@"title": KKLocalized(@"深色"),     @"mode": KKThemeModeDark},
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
    NSString *current = [KKTheme userPreferredMode];
    id mode = opt[@"mode"];
    if ([mode isKindOfClass:[NSNull class]]) {
        return current == nil;
    }
    return [mode isKindOfClass:[NSString class]] && [(NSString *)mode isEqualToString:current];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return countcoordinatesX(50);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *opt = self.options[indexPath.row];
    if ([self isOptionCurrent:opt]) return;

    id mode = opt[@"mode"];
    NSString *toSave = [mode isKindOfClass:[NSNull class]] ? nil : (NSString *)mode;
    [KKTheme setUserPreferredMode:toSave];
    [tableView reloadData];

    // 立即应用：找到 keyWindow 并刷新 overrideUserInterfaceStyle。
    // 与语言切换不同，主题切换不需要重启。
    UIWindow *keyWindow = nil;
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]
            && scene.activationState == UISceneActivationStateForegroundActive) {
            keyWindow = ((UIWindowScene *)scene).keyWindow;
            break;
        }
    }
    [KKTheme applyToWindow:keyWindow];
}

@end
