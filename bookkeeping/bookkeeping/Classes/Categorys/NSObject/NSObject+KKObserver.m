//
//  NSObject+KKObserver.m
//  bookkeeping
//

#import "NSObject+KKObserver.h"
#import <objc/runtime.h>

#pragma mark - Internal token holder

// Each call to kk_observeNotification: creates one of these. It owns the
// NSNotificationCenter observer token and removes it in -dealloc. We attach
// an array of these to the observing object; when the object deallocs, the
// array deallocs, the tokens dealloc, and observers are unregistered.
@interface KKObserverToken : NSObject
@property (nonatomic, strong) id token;
@end

@implementation KKObserverToken
- (void)dealloc {
    if (_token) {
        [[NSNotificationCenter defaultCenter] removeObserver:_token];
    }
}
@end

#pragma mark - NSObject (KKObserver)

@implementation NSObject (KKObserver)

- (NSMutableArray<KKObserverToken *> *)kk_observerTokens {
    NSMutableArray *tokens = objc_getAssociatedObject(self, _cmd);
    if (!tokens) {
        tokens = [NSMutableArray array];
        objc_setAssociatedObject(self, _cmd, tokens, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return tokens;
}

- (void)kk_observeNotification:(NSNotificationName)name
                    usingBlock:(void (^)(NSNotification *))block {
    [self kk_observeNotification:name object:nil usingBlock:block];
}

- (void)kk_observeNotification:(NSNotificationName)name
                        object:(id)object
                    usingBlock:(void (^)(NSNotification *))block {
    if (block == nil) return;
    id token = [[NSNotificationCenter defaultCenter] addObserverForName:name
                                                                 object:object
                                                                  queue:[NSOperationQueue mainQueue]
                                                             usingBlock:block];
    KKObserverToken *holder = [[KKObserverToken alloc] init];
    holder.token = token;
    [[self kk_observerTokens] addObject:holder];
}

@end
