/**
 * 路由协议
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RouterProtocol <NSObject>

@property (nonatomic, weak) id<RouterProtocol> delegate;

- (void)routerEventWithName:(NSString *)eventName data:(id)data;

@end

NS_ASSUME_NONNULL_END 