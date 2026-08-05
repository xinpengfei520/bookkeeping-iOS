/**
 * Siri 捷径管理页
 * 说明见 SiriShortcutsController.h
 */

#import "SiriShortcutsController.h"
#import <Intents/Intents.h>
#import <IntentsUI/IntentsUI.h>
#import <Masonry/Masonry.h>

NSString * const KKActivityTypeBook  = @"com.xpf.light.record.activity.book";
NSString * const KKActivityTypeRate  = @"com.xpf.light.record.activity.rate";
NSString * const KKActivityTypeChart = @"com.xpf.light.record.activity.chart";

#pragma mark - Cell
@interface SiriShortcutCell : UITableViewCell

@property (nonatomic, strong) UILabel *titleLab;    // 打开记账键盘
@property (nonatomic, strong) UILabel *phraseLab;   // 对 Siri 说 "xxx"
@property (nonatomic, strong) UIButton *actionBtn;  // 添加到 Siri / 编辑

@end

@implementation SiriShortcutCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor systemBackgroundColor];

        _titleLab = [[UILabel alloc] init];
        _titleLab.font = [UIFont systemFontOfSize:AdjustFont(16) weight:UIFontWeightMedium];
        _titleLab.textColor = kColor_Text_Black;
        [self.contentView addSubview:_titleLab];

        _phraseLab = [[UILabel alloc] init];
        _phraseLab.font = [UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight];
        _phraseLab.textColor = kColor_Text_Gary;
        _phraseLab.numberOfLines = 2;
        [self.contentView addSubview:_phraseLab];

        // 圆角描边胶囊按钮（网易云同款样式，用品牌绿）
        _actionBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        UIButtonConfiguration *cfg = [UIButtonConfiguration plainButtonConfiguration];
        cfg.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
        cfg.contentInsets = NSDirectionalEdgeInsetsMake(6, 14, 6, 14);
        cfg.baseForegroundColor = kColor_Main_Color;
        cfg.background.strokeColor = kColor_Main_Color;
        cfg.background.strokeWidth = 1;
        cfg.titleTextAttributesTransformer = ^NSDictionary<NSAttributedStringKey, id> *(NSDictionary<NSAttributedStringKey, id> *incoming) {
            NSMutableDictionary *attrs = [incoming mutableCopy];
            attrs[NSFontAttributeName] = [UIFont systemFontOfSize:AdjustFont(13)];
            return attrs;
        };
        _actionBtn.configuration = cfg;
        [_actionBtn setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [self.contentView addSubview:_actionBtn];

        [_titleLab mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(countcoordinatesX(15));
            make.top.equalTo(self.contentView).offset(countcoordinatesX(14));
        }];
        [_phraseLab mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self->_titleLab);
            make.top.equalTo(self->_titleLab.mas_bottom).offset(6);
            make.right.lessThanOrEqualTo(self->_actionBtn.mas_left).offset(-10);
            make.bottom.lessThanOrEqualTo(self.contentView).offset(-countcoordinatesX(14));
        }];
        [_actionBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.contentView).offset(-countcoordinatesX(15));
            make.centerY.equalTo(self.contentView);
        }];
    }
    return self;
}

@end


#pragma mark - 声明
@interface SiriShortcutsController ()<UITableViewDelegate, UITableViewDataSource,
    INUIAddVoiceShortcutViewControllerDelegate, INUIEditVoiceShortcutViewControllerDelegate>

@property (nonatomic, strong) UITableView *table;
@property (nonatomic, copy  ) NSArray<NSArray *> *items;    // @[type, title, 建议口令]
// 已添加的语音捷径：activityType → INVoiceShortcut（含用户实际录的口令）
@property (nonatomic, strong) NSMutableDictionary<NSString *, INVoiceShortcut *> *added;

@end


#pragma mark - 实现
@implementation SiriShortcutsController

+ (NSUserActivity *)activityWithType:(NSString *)type {
    NSString *title = KKLocalized(@"打开记账键盘");
    NSString *phrase = KKLocalized(@"记一笔账");
    if ([type isEqualToString:KKActivityTypeRate]) {
        title = KKLocalized(@"看今日汇率");
        phrase = KKLocalized(@"今日汇率");
    } else if ([type isEqualToString:KKActivityTypeChart]) {
        title = KKLocalized(@"看图表账单");
        phrase = KKLocalized(@"看看账单");
    }
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:type];
    activity.title = title;
    activity.suggestedInvocationPhrase = phrase;
    activity.eligibleForPrediction = YES;
    activity.eligibleForSearch = YES;
    activity.persistentIdentifier = type;
    return activity;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = KKLocalized(@"Siri 捷径");
    self.view.backgroundColor = kColor_BG;
    self.added = [NSMutableDictionary dictionary];

    [self.view addSubview:self.table];
    [self.table mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self reloadVoiceShortcuts];
}

// 拉取系统里已添加的语音捷径，按 activityType 归类（决定按钮显示"添加到 Siri"还是"编辑"）
- (void)reloadVoiceShortcuts {
    @weakify(self)
    [[INVoiceShortcutCenter sharedCenter] getAllVoiceShortcutsWithCompletion:^(NSArray<INVoiceShortcut *> *voiceShortcuts, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self)
            [self.added removeAllObjects];
            for (INVoiceShortcut *vs in voiceShortcuts) {
                NSString *type = vs.shortcut.userActivity.activityType;
                if (type.length) {
                    self.added[type] = vs;
                }
            }
            [self.table reloadData];
        });
    }];
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"SiriShortcutCell";
    SiriShortcutCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[SiriShortcutCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }

    NSArray *item = self.items[indexPath.row];
    NSString *type = item[0];
    cell.titleLab.text = item[1];

    INVoiceShortcut *existing = self.added[type];
    UIButtonConfiguration *cfg = cell.actionBtn.configuration;
    if ([type isEqualToString:@"__intent__"]) {
        // AppIntents 对话式记账：默认口令即可用；易误触发时去快捷指令 App 包一层自命名指令
        cell.phraseLab.text = [NSString stringWithFormat:KKLocalized(@"对 Siri 说 “%@”"), item[2]];
        cfg.title = KKLocalized(@"自定口令");
    } else if (existing) {
        // 已添加：显示用户实际录的口令 + 编辑（编辑页里自带移除）
        cell.phraseLab.text = [NSString stringWithFormat:KKLocalized(@"对 Siri 说 “%@”"), existing.invocationPhrase];
        cfg.title = KKLocalized(@"编辑");
    } else {
        cell.phraseLab.text = [NSString stringWithFormat:KKLocalized(@"对 Siri 说 “%@”"), item[2]];
        cfg.title = KKLocalized(@"添加到 Siri");
    }
    cell.actionBtn.configuration = cfg;
    cell.actionBtn.tag = indexPath.row;
    [cell.actionBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [cell.actionBtn addTarget:self action:@selector(actionBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}


#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return countcoordinatesX(84);
}

// 顶部提示：「记一笔」对话式捷径无需添加
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return countcoordinatesX(64);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = kColor_BG;
    UILabel *lab = [[UILabel alloc] init];
    lab.font = [UIFont systemFontOfSize:AdjustFont(11) weight:UIFontWeightLight];
    lab.textColor = kColor_Text_Gary;
    lab.numberOfLines = 0;
    lab.text = KKLocalized(@"「记一笔」默认口令易被同类 App 抢走时，点“自定口令”按指引设置专属口令；其余捷径可直接录制你自己的口令：");
    [view addSubview:lab];
    [lab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(view).offset(countcoordinatesX(15));
        make.right.equalTo(view).offset(-countcoordinatesX(15));
        make.bottom.equalTo(view).offset(-8);
    }];
    return view;
}


#pragma mark - 点击
- (void)actionBtnClick:(UIButton *)btn {
    NSArray *item = self.items[btn.tag];
    NSString *type = item[0];

    // 对话式「记一笔」：系统不提供给 AppIntents 录口令的界面，
    // 100% 可靠的自定口令方式是在快捷指令 App 里包一层自命名指令 —— 给出步骤指引。
    if ([type isEqualToString:@"__intent__"]) {
        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:KKLocalized(@"自定义「记一笔」口令")
                             message:KKLocalized(@"默认口令被其它 App 抢走时，可以这样设置一个 100% 精准的口令：\n\n1. 打开「快捷指令」App\n2. 点右上角 + 新建快捷指令\n3. 搜索“记呀”，选择「记一笔」\n4. 把快捷指令命名为你想说的话（如“快记”）\n\n之后对 Siri 说出这个名字，就会直接进入报金额的对话，无需打开 App。")
                      preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:KKLocalized(@"取消") style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:KKLocalized(@"去快捷指令")
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
            NSURL *url = [NSURL URLWithString:@"shortcuts://"];
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    INVoiceShortcut *existing = self.added[type];

    if (existing) {
        // 系统编辑页：更改语音指令 / 移除快捷指令
        INUIEditVoiceShortcutViewController *vc =
            [[INUIEditVoiceShortcutViewController alloc] initWithVoiceShortcut:existing];
        vc.delegate = self;
        [self presentViewController:vc animated:YES completion:nil];
    } else {
        // 系统添加页：录制自定义口令
        NSUserActivity *activity = [SiriShortcutsController activityWithType:type];
        INShortcut *shortcut = [[INShortcut alloc] initWithUserActivity:activity];
        INUIAddVoiceShortcutViewController *vc =
            [[INUIAddVoiceShortcutViewController alloc] initWithShortcut:shortcut];
        vc.delegate = self;
        [self presentViewController:vc animated:YES completion:nil];
    }
}


#pragma mark - INUIAddVoiceShortcutViewControllerDelegate
- (void)addVoiceShortcutViewController:(INUIAddVoiceShortcutViewController *)controller
    didFinishWithVoiceShortcut:(INVoiceShortcut *)voiceShortcut error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
    [self reloadVoiceShortcuts];
}

- (void)addVoiceShortcutViewControllerDidCancel:(INUIAddVoiceShortcutViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - INUIEditVoiceShortcutViewControllerDelegate
- (void)editVoiceShortcutViewController:(INUIEditVoiceShortcutViewController *)controller
    didUpdateVoiceShortcut:(INVoiceShortcut *)voiceShortcut error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
    [self reloadVoiceShortcuts];
}

- (void)editVoiceShortcutViewController:(INUIEditVoiceShortcutViewController *)controller
    didDeleteVoiceShortcutWithIdentifier:(NSUUID *)deletedVoiceShortcutIdentifier {
    [controller dismissViewControllerAnimated:YES completion:nil];
    [self reloadVoiceShortcuts];
}

- (void)editVoiceShortcutViewControllerDidCancel:(INUIEditVoiceShortcutViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - get
- (UITableView *)table {
    if (!_table) {
        _table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _table.delegate = self;
        _table.dataSource = self;
        _table.backgroundColor = kColor_BG;
        _table.showsVerticalScrollIndicator = NO;
        _table.separatorInset = UIEdgeInsetsMake(0, countcoordinatesX(15), 0, 0);
        _table.separatorColor = kColor_Line_Color;
    }
    return _table;
}

- (NSArray<NSArray *> *)items {
    if (!_items) {
        _items = @[
            // 特殊行：AppIntents 对话式记账（不走 INShortcut，见 actionBtnClick）
            @[@"__intent__",       KKLocalized(@"记一笔（对话式）"), KKLocalized(@"用记呀记一笔")],
            @[KKActivityTypeBook,  KKLocalized(@"打开记账键盘"), KKLocalized(@"记一笔账")],
            @[KKActivityTypeRate,  KKLocalized(@"看今日汇率"),   KKLocalized(@"今日汇率")],
            @[KKActivityTypeChart, KKLocalized(@"看图表账单"),   KKLocalized(@"看看账单")],
        ];
    }
    return _items;
}

@end
