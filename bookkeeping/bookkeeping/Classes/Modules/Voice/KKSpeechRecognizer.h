//
//  KKSpeechRecognizer.h
//  bookkeeping
//
//  Speech + AVAudioEngine 的一次性录音识别封装（长按说一句话的场景）。
//  一个实例只服务一次录音；所有回调都在主线程。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKSpeechRecognizer : NSObject

@property (nonatomic, assign, readonly) BOOL isRunning;

/// 录音电平 0~1，驱动波形动画（主线程回调，随音频 buffer 到达节奏触发）
@property (nonatomic, copy, nullable) void (^levelHandler)(float level);
/// 录音被系统打断（来电/Siri）时回调，此时识别已被取消，调用方撤掉 UI 即可
@property (nonatomic, copy, nullable) void (^interruptedHandler)(void);

/// 申请麦克风 + 语音识别两个权限（首次会依次弹系统窗）。
/// granted=NO 时 message 是可直接弹给用户的引导文案。主线程回调。
+ (void)requestPermission:(void (^)(BOOL granted, NSString *_Nullable message))completion;

/// 开始录音识别，partial 随说话实时回调当前识别文本。
/// 返回 NO 表示启动失败（识别器不可用/音频会话被占/模拟器无麦克风）。
- (BOOL)startWithPartial:(void (^)(NSString *text))partial;

/// 结束录音并等待最终结果；识别器 1.5 秒内没给终稿就用最后一次 partial 兜底。
- (void)stopWithCompletion:(void (^)(NSString *finalText))completion;

/// 取消：丢弃结果，不回调。
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
