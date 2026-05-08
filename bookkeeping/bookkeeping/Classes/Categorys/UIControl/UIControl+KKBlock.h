//
//  UIControl+KKBlock.h
//  bookkeeping
//
//  ReactiveObjC's
//      [[btn rac_signalForControlEvents:UIControlEventTouchUpInside]
//          subscribeNext:^(UIControl *x) { ... }];
//  collapses to:
//      [btn kk_addEventHandler:^(UIControl *x) { ... }
//             forControlEvents:UIControlEventTouchUpInside];
//
//  Block lifetime is tied to the UIControl: the proxy owning the block is
//  retained by the control via an associated array, so blocks live exactly
//  as long as the control does.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIControl (KKBlock)

- (void)kk_addEventHandler:(void (^)(__kindof UIControl *sender))block
          forControlEvents:(UIControlEvents)events;

@end

NS_ASSUME_NONNULL_END
