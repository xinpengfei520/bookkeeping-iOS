/**
 * 分享
 * @author 郑业强 2018-12-20 创建文件
 */

#import "ShareController.h"
#import "ShareShot.h"
#import "ShareOrder.h"
#import "ShareBadge.h"
#import "ShareBottom.h"


#pragma mark - 声明
@interface ShareController()<UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) ShareShot *shot1;
@property (nonatomic, strong) ShareOrder *shot2;
@property (nonatomic, strong) ShareBadge *shot3;
@property (nonatomic, strong) ShareBottom *bottom;

@end


#pragma mark - 实现
@implementation ShareController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"分享";
    [self.view setBackgroundColor:kColor_Line_Color];
    [self scroll];
    [self shot1];
//    [self shot2];
//    [self shot3];
    // [self bottom];
//    _shot1.hidden = YES;
//    _shot2.hidden = YES;
    
    [self setData];
}

- (void)setData {
    [self.shot1 setModel:_model];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView.contentOffset.y < -54) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


#pragma mark - get
- (UIScrollView *)scroll {
    if (!_scroll) {
        _scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - self.bottom.height)];
        // BKCRefreshHeader 已移除（详见 BKCCollection.m 同样改动）。dismiss 由 iOS modal 自带手势处理。
        [_scroll setDelegate:self];
        [self.view addSubview:_scroll];
    }
    return _scroll;
}

- (ShareShot *)shot1 {
    if (!_shot1) {
        _shot1 = [ShareShot loadFirstNib:({
            CGFloat paddingW = countcoordinatesX(50);
            CGFloat paddingH = countcoordinatesX(30);
            CGFloat left = paddingW;
            CGFloat top = paddingH;
            CGFloat height = self.scroll.height - top - paddingH - countcoordinatesX(200);
            CGRectMake(left, top, SCREEN_WIDTH - left * 2, height);
        })];
        [self.scroll addSubview:_shot1];
    }
    return _shot1;
}

- (ShareOrder *)shot2 {
    if (!_shot2) {
        _shot2 = [ShareOrder loadFirstNib:self.shot1.frame];
        [self.scroll addSubview:_shot2];
    }
    return _shot2;
}

- (ShareBadge *)shot3 {
    if (!_shot3) {
        _shot3 = [ShareBadge loadFirstNib:self.shot1.frame];
        [self.scroll addSubview:_shot3];
    }
    return _shot3;
}

// - (ShareBottom *)bottom {
//     if (!_bottom) {
//         _bottom = [ShareBottom loadCode:({
//             CGFloat height = countcoordinatesX(120) + SafeAreaBottomHeight + NavigationBarHeight;
//             CGFloat top = SCREEN_HEIGHT - height;
//             CGRectMake(0, top, SCREEN_WIDTH, height);
//         })];
//         [self.view addSubview:_bottom];
//     }
//     return _bottom;
// }

@end
