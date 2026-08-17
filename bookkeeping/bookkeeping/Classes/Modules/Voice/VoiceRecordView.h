//
//  VoiceRecordView.h
//  bookkeeping
//
//  长按 + 号时的录音浮层：实时识别文字 + 波形 + 上滑取消提示。
//  纯展示，不持有识别器；生命周期由 HomeController 驱动。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VoiceRecordView : UIView

+ (instancetype)showInView:(UIView *)view;

- (void)updateText:(NSString *)text;        // ASR partial 实时文本
- (void)updateLevel:(float)level;           // 录音电平 0~1，驱动波形
- (void)setCancelState:(BOOL)cancelState;   // 上滑越过阈值：提示变红「松开取消」
- (void)setAlbumState:(BOOL)albumState;     // 左滑越过阈值：提示「松开选择相册」
- (void)showRecognizing;                    // 松手后等终稿的过渡态
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
