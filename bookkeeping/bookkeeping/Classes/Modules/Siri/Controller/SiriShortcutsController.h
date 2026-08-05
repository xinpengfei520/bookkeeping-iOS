/**
 * Siri 捷径管理页（设置 → Siri 捷径）
 *
 * 仿系统标准交互（参考网易云音乐）：列出可添加的捷径，每条显示建议口令；
 * 未添加的显示「添加到 Siri」→ 弹 INUIAddVoiceShortcutViewController 录自定义口令；
 * 已添加的显示实际口令 +「编辑」→ 弹 INUIEditVoiceShortcutViewController，
 * 里面自带"更改语音指令 / 移除快捷指令"。
 *
 * 这三条捷径基于 NSUserActivity（对 Siri 说口令 → 打开 App 到对应页面），
 * 路由在 AppDelegate 的 continueUserActivity 里。参数化的「记一笔」
 * （AppIntents 对话式，见 BookIntents.swift）不需要添加即可用，页面顶部作提示展示。
 */

#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

// NSUserActivity 类型（须与 Info.plist 的 NSUserActivityTypes 一致）
extern NSString * const KKActivityTypeBook;     // 打开记账键盘
extern NSString * const KKActivityTypeRate;     // 打开今日汇率
extern NSString * const KKActivityTypeChart;    // 打开图表账单

@interface SiriShortcutsController : BaseViewController

/// 构造某个类型的 NSUserActivity（标题/建议口令已配好，AppDelegate 路由用同一份类型常量）
+ (NSUserActivity *)activityWithType:(NSString *)type;

@end

NS_ASSUME_NONNULL_END
