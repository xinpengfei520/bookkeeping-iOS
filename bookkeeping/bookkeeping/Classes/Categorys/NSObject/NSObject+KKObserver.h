//
//  NSObject+KKObserver.h
//  bookkeeping
//
//  ReactiveObjC's
//      [[[[NSNotificationCenter defaultCenter]
//             rac_addObserverForName:NAME object:nil]
//             takeUntil:self.rac_willDeallocSignal]
//             subscribeNext:^(NSNotification *x) { ... }];
//  collapses to:
//      [self kk_observeNotification:NAME usingBlock:^(NSNotification *x) { ... }];
//
//  The observer auto-removes when self deallocs (an internal token holder is
//  attached as an associated object and removes its observer in its own
//  -dealloc).
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (KKObserver)

/// Observe a notification by name. Block runs on the main queue.
/// The observer is auto-removed when the receiver deallocates.
- (void)kk_observeNotification:(NSNotificationName)name
                    usingBlock:(void (^)(NSNotification *note))block;

/// Variant with an optional sender filter.
- (void)kk_observeNotification:(NSNotificationName)name
                        object:(nullable id)object
                    usingBlock:(void (^)(NSNotification *note))block;

@end

NS_ASSUME_NONNULL_END
