//
//  KKSpeechRecognizer.m
//  bookkeeping
//

#import "KKSpeechRecognizer.h"
#import <Speech/Speech.h>
#import <AVFoundation/AVFoundation.h>

@interface KKSpeechRecognizer ()

@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, strong) SFSpeechRecognizer *recognizer;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *request;
@property (nonatomic, strong) SFSpeechRecognitionTask *task;
@property (nonatomic, strong) AVAudioEngine *engine;
@property (nonatomic, copy  ) NSString *lastText;
@property (nonatomic, copy  ) void (^stopCompletion)(NSString *finalText);

@end

@implementation KKSpeechRecognizer

#pragma mark - 权限

+ (void)requestPermission:(void (^)(BOOL, NSString *))completion {
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (!granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, KKLocalized(@"请在系统设置中允许记呀访问麦克风"));
            });
            return;
        }
        [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                BOOL ok = (status == SFSpeechRecognizerAuthorizationStatusAuthorized);
                completion(ok, ok ? nil : KKLocalized(@"请在系统设置中允许记呀使用语音识别"));
            });
        }];
    }];
}

#pragma mark - 录音识别

- (BOOL)startWithPartial:(void (^)(NSString *))partial {
    if (_isRunning) return NO;

    // 跟随 App 语言选中文/英文识别器；解析器只认中文话术，英文模式下确认卡片仍可手改
    NSString *lang = [KKI18n effectiveLanguageCode];
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:[lang hasPrefix:@"zh"] ? @"zh-CN" : @"en-US"];
    _recognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
    if (!_recognizer || !_recognizer.isAvailable) return NO;

    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;
    // duckOthers：压低正在放的音乐而不是掐断它
    [session setCategory:AVAudioSessionCategoryRecord withOptions:AVAudioSessionCategoryOptionDuckOthers error:&error];
    if (error || ![session setActive:YES error:&error]) return NO;

    _request = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    _request.shouldReportPartialResults = YES;
    // 不强制 on-device（requiresOnDeviceRecognition）：支持的设备系统会自动优先本地模型，
    // 强制反而会在模型未下载好时直接失败

    _engine = [[AVAudioEngine alloc] init];
    AVAudioInputNode *input = _engine.inputNode;
    AVAudioFormat *format = [input outputFormatForBus:0];
    if (format.sampleRate <= 0 || format.channelCount == 0) {   // 模拟器/无麦克风兜底
        [self deactivateSession];
        return NO;
    }
    @weakify(self)
    [input installTapOnBus:0 bufferSize:1024 format:format block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
        @strongify(self)
        [self.request appendAudioPCMBuffer:buffer];
        // RMS 电平驱动波形（隔 16 帧取样已足够平滑）
        float *samples = buffer.floatChannelData ? buffer.floatChannelData[0] : NULL;
        if (samples && buffer.frameLength > 0 && self.levelHandler) {
            float sum = 0;
            NSUInteger count = 0;
            for (NSUInteger i = 0; i < buffer.frameLength; i += 16) { sum += samples[i] * samples[i]; count++; }
            float rms = count ? sqrtf(sum / count) : 0;
            float level = MIN(1.0f, rms * 8.0f);   // 正常说话音量映射到 0.3~0.9
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.levelHandler && self.isRunning) self.levelHandler(level);
            });
        }
    }];
    [_engine prepare];
    if (![_engine startAndReturnError:&error]) {
        [input removeTapOnBus:0];
        [self deactivateSession];
        return NO;
    }

    _task = [_recognizer recognitionTaskWithRequest:_request resultHandler:^(SFSpeechRecognitionResult *result, NSError *taskError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self)
            if (!self) return;
            if (result) {
                self.lastText = result.bestTranscription.formattedString;
                if (partial && self.isRunning && !self.stopCompletion) partial(self.lastText);
                if (result.isFinal) [self deliverFinal];
            }
            if (taskError) [self deliverFinal];   // 出错用最后一次 partial 兜底
        });
    }];
    _isRunning = YES;

    // 来电/Siri 打断：直接取消并通知调用方撤 UI
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioInterrupted:)
                                                 name:AVAudioSessionInterruptionNotification object:nil];
    return YES;
}

- (void)stopWithCompletion:(void (^)(NSString *))completion {
    if (!_isRunning || _stopCompletion) {
        if (completion) completion(_lastText ?: @"");
        return;
    }
    _stopCompletion = [completion copy];
    [self teardownAudio];
    [_request endAudio];
    // 识别器 1.5s 内没给 isFinal 就用最后一次 partial 交差（短句识别正常几百 ms 内返回）
    @weakify(self)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self)
        [self deliverFinal];
    });
}

- (void)cancel {
    _stopCompletion = nil;
    [self teardownAudio];
    [_task cancel];
    _task = nil;
    _isRunning = NO;
    [self deactivateSession];
}

#pragma mark - private

// 主线程。终稿只交付一次。
- (void)deliverFinal {
    if (!_stopCompletion) return;
    void (^completion)(NSString *) = _stopCompletion;
    _stopCompletion = nil;
    [_task cancel];
    _task = nil;
    _isRunning = NO;
    [self deactivateSession];
    completion(_lastText ?: @"");
}

- (void)teardownAudio {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
    if (_engine.isRunning) [_engine stop];
    [_engine.inputNode removeTapOnBus:0];
}

- (void)deactivateSession {
    // 释放音频会话让别的 App 恢复音量；放后台队列避免卡主线程
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    });
}

- (void)audioInterrupted:(NSNotification *)note {
    NSUInteger type = [note.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (type != AVAudioSessionInterruptionTypeBegan) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isRunning) return;
        [self cancel];
        if (self.interruptedHandler) self.interruptedHandler();
    });
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
