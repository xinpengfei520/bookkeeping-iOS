//
//  KKOCRRecognizer.m
//  bookkeeping
//

#import "KKOCRRecognizer.h"
#import <Vision/Vision.h>

static const CGFloat kMaxSide = 2048;

@implementation KKOCRRecognizer

+ (void)recognizeImages:(NSArray<UIImage *> *)images
             completion:(void (^)(NSArray<NSString *> *texts))completion {
    NSParameterAssert(completion);
    if (!completion) return;
    if (images.count == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{ completion(@[]); });
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableArray<NSString *> *texts = [NSMutableArray arrayWithCapacity:images.count];
        for (UIImage *image in images) {
            [texts addObject:[self recognizeImage:image] ?: @""];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(texts);
        });
    });
}

+ (NSString *)recognizeImage:(UIImage *)image {
    UIImage *prepared = [self downsample:image maxSide:kMaxSide];
    CGImageRef cgImage = prepared.CGImage;
    if (!cgImage) return @"";

    VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc] init];
    request.recognitionLevel = VNRequestTextRecognitionLevelAccurate;
    request.usesLanguageCorrection = YES;
    request.recognitionLanguages = @[@"zh-Hans", @"en-US"];

    NSError *handlerError = nil;
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:cgImage
                                                                        orientation:[self cgOrientation:prepared.imageOrientation]
                                                                            options:@{}];
    BOOL ok = [handler performRequests:@[request] error:&handlerError];
    if (!ok) return @"";
    return [self joinObservations:request.results];
}

+ (NSString *)joinObservations:(NSArray<VNRecognizedTextObservation *> *)observations {
    if (observations.count == 0) return @"";
    NSArray *sorted = [observations sortedArrayUsingComparator:^NSComparisonResult(VNRecognizedTextObservation *a, VNRecognizedTextObservation *b) {
        CGFloat ay = CGRectGetMidY(a.boundingBox);
        CGFloat by = CGRectGetMidY(b.boundingBox);
        // Vision 坐标原点在左下，y 越大越靠上
        if (fabs(ay - by) > 0.018) return ay > by ? NSOrderedAscending : NSOrderedDescending;
        CGFloat ax = CGRectGetMinX(a.boundingBox);
        CGFloat bx = CGRectGetMinX(b.boundingBox);
        if (ax < bx) return NSOrderedAscending;
        if (ax > bx) return NSOrderedDescending;
        return NSOrderedSame;
    }];

    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    NSMutableString *current = [NSMutableString string];
    CGFloat lastY = CGFLOAT_MAX;
    for (VNRecognizedTextObservation *obs in sorted) {
        NSString *piece = [[obs topCandidates:1].firstObject string];
        if (piece.length == 0) continue;
        CGFloat y = CGRectGetMidY(obs.boundingBox);
        if (lastY != CGFLOAT_MAX && fabs(y - lastY) > 0.018 && current.length) {
            [lines addObject:[current copy]];
            [current setString:@""];
        }
        if (current.length) [current appendString:@" "];
        [current appendString:piece];
        lastY = y;
    }
    if (current.length) [lines addObject:[current copy]];
    return [lines componentsJoinedByString:@"\n"];
}

+ (UIImage *)downsample:(UIImage *)image maxSide:(CGFloat)maxSide {
    CGSize size = image.size;
    CGFloat longest = MAX(size.width, size.height);
    if (longest <= maxSide || longest <= 0) return image;
    CGFloat scale = maxSide / longest;
    CGSize newSize = CGSizeMake(floor(size.width * scale), floor(size.height * scale));
    UIGraphicsBeginImageContextWithOptions(newSize, YES, 1);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *out = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return out ?: image;
}

+ (CGImagePropertyOrientation)cgOrientation:(UIImageOrientation)o {
    switch (o) {
        case UIImageOrientationDown: return kCGImagePropertyOrientationDown;
        case UIImageOrientationLeft: return kCGImagePropertyOrientationLeft;
        case UIImageOrientationRight: return kCGImagePropertyOrientationRight;
        case UIImageOrientationUpMirrored: return kCGImagePropertyOrientationUpMirrored;
        case UIImageOrientationDownMirrored: return kCGImagePropertyOrientationDownMirrored;
        case UIImageOrientationLeftMirrored: return kCGImagePropertyOrientationLeftMirrored;
        case UIImageOrientationRightMirrored: return kCGImagePropertyOrientationRightMirrored;
        default: return kCGImagePropertyOrientationUp;
    }
}

@end
