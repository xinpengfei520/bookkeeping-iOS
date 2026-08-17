//
//  OCRConfirmView.h
//  bookkeeping
//
//  多图 OCR 确认：1 笔复用 VoiceConfirmView；多笔用可编辑列表，
//  点按一行再进单笔确认卡，划掉不要的，最后一并落库。
//

#import <UIKit/UIKit.h>

@class KKParsedBookEntry, BKCModel, BookDetailModel;

NS_ASSUME_NONNULL_BEGIN

@interface OCRConfirmView : UIView

/// 弹出确认层。1 笔走 VoiceConfirmView；多笔走本列表。
/// 用户点确认后回调组装好的 BookDetailModel 数组（临时负数 bookId）。
/// 取消/关闭不回调。
+ (void)showWithEntries:(NSArray<KKParsedBookEntry *> *)entries
             categories:(NSArray<BKCModel *> *)categories
                confirm:(void (^)(NSArray<BookDetailModel *> *models))confirm;

@end

NS_ASSUME_NONNULL_END
