//
//  UIControl+KKBlock.m
//  bookkeeping
//

#import "UIControl+KKBlock.h"
#import <objc/runtime.h>

#pragma mark - Internal proxy

// One proxy per call. Stored on the control via an associated array so the
// block lives as long as the control. addTarget:action:forControlEvents:
// holds a weak reference to the proxy; once the array is released (when the
// control deallocs), the proxy is released, the action target slot becomes
// nil, and UIControl no longer fires it.
@interface KKControlBlockProxy : NSObject
@property (nonatomic, copy) void (^block)(__kindof UIControl *);
- (void)invoke:(__kindof UIControl *)sender;
@end

@implementation KKControlBlockProxy
- (void)invoke:(__kindof UIControl *)sender {
    if (self.block) self.block(sender);
}
@end

#pragma mark - UIControl (KKBlock)

@implementation UIControl (KKBlock)

- (NSMutableArray<KKControlBlockProxy *> *)kk_blockProxies {
    NSMutableArray *arr = objc_getAssociatedObject(self, _cmd);
    if (!arr) {
        arr = [NSMutableArray array];
        objc_setAssociatedObject(self, _cmd, arr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return arr;
}

- (void)kk_addEventHandler:(void (^)(__kindof UIControl *))block
          forControlEvents:(UIControlEvents)events {
    if (block == nil) return;
    KKControlBlockProxy *proxy = [[KKControlBlockProxy alloc] init];
    proxy.block = block;
    [[self kk_blockProxies] addObject:proxy];
    [self addTarget:proxy action:@selector(invoke:) forControlEvents:events];
}

@end
