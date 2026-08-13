//
//  VoiceConfirmView.h
//  bookkeeping
//
//  语音记账确认卡片：展示原始识别文本 + 金额/类别/日期/备注四个可编辑字段。
//  识别结果永远过这张卡片确认后才落库 —— ASR 会错，静默记错账比慢一步伤害大。
//

#import <UIKit/UIKit.h>

@class KKParsedBookEntry, BKCModel, BookDetailModel;

NS_ASSUME_NONNULL_BEGIN

@interface VoiceConfirmView : UIView

/// 弹出确认卡片（加在 keyWindow 上）。用户点「确认记账」时回调组装好的
/// BookDetailModel（临时负数 bookId），调用方发 NOTIFICATION_BOOK_ADD 即可。
/// 取消/关闭不回调。
+ (void)showWithEntry:(KKParsedBookEntry *)entry
           categories:(NSArray<BKCModel *> *)categories
              confirm:(void (^)(BookDetailModel *model))confirm;

@end

NS_ASSUME_NONNULL_END
