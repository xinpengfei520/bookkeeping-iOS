//
//  HomeAddBar.h
//  bookkeeping
//
//  首页底部记账条：默认只露圆形 +。
//  点 + 记一笔；长按展开语音 / 图片，左滑或右滑松手进入对应入口，松手后两侧收回。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HomeAddBar : UIView

@property (nonatomic, copy) void (^tapBook)(void);
@property (nonatomic, copy) void (^tapVoice)(void);
@property (nonatomic, copy) void (^tapPhoto)(void);

/// 按住中间 + 滑动。side: -1 左（语音），1 右（图片），0 松在中间。
@property (nonatomic, copy, nullable) void (^slideEnded)(NSInteger side);

@end

NS_ASSUME_NONNULL_END
