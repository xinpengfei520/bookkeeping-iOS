//
//  KKOCRRecognizer.h
//  bookkeeping
//
//  端上账单 OCR：Vision VNRecognizeTextRequest，中英准确模式。
//  不碰网络、不碰 UI；多图串行识别，主线程回调。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKOCRRecognizer : NSObject

/// 识别一组图片。返回与 images 等长的文本数组（失败的位置为空串）。
/// completion 一定在主线程、且只回调一次。
+ (void)recognizeImages:(NSArray<UIImage *> *)images
             completion:(void (^)(NSArray<NSString *> *texts))completion;

@end

NS_ASSUME_NONNULL_END
