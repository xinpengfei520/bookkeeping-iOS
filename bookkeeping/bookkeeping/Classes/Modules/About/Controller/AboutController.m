/**
 * 关于
 * @author 郑业强 2018-12-20 创建文件
 */

#import "AboutController.h"

#pragma mark - 声明
@interface AboutController()

@property (nonatomic, strong) UIImageView *image;
@property (nonatomic, strong) UILabel *nameLab;
@property (nonatomic, strong) UIButton *share;
@property (nonatomic, strong) UILabel *version;

@end


#pragma mark - 实现
@implementation AboutController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.hbd_barHidden = NO;
    self.hbd_barTintColor = kColor_Main_Color;
    [self setNavTitle:@"关于"];
    [self image];
    [self nameLab];
    [self share];
    [self version];
}


#pragma mark - get
- (UIImageView *)image {
    if (!_image) {
        _image = [[UIImageView alloc] initWithFrame:({
            CGFloat left = countcoordinatesX(120);
            CGFloat width = SCREEN_WIDTH - left * 2;
            CGRectMake(left, countcoordinatesX(160), width, width);
        })];
        _image.contentMode = UIViewContentModeScaleAspectFit;
        _image.image = [UIImage imageNamed:@"icon_about"];
        [self.view addSubview:_image];
    }
    return _image;
}

- (UILabel *)nameLab {
    if (!_nameLab) {
        _nameLab = [[UILabel alloc] initWithFrame:CGRectMake(0, _image.bottom + countcoordinatesX(20), SCREEN_WIDTH, countcoordinatesX(20))];
        _nameLab.text = @"财务自由从「记呀」开始";
        _nameLab.textAlignment = NSTextAlignmentCenter;
        _nameLab.font = [UIFont systemFontOfSize:AdjustFont(12) weight:UIFontWeightLight];
        [self.view addSubview:_nameLab];
    }
    return _nameLab;
}

- (UIButton *)share {
    if (!_share) {
        _share = [UIButton buttonWithType:UIButtonTypeCustom];
        _share.frame = ({
            CGFloat left = SCREEN_WIDTH / 3;
            CGFloat width = SCREEN_WIDTH - left * 2;
            CGFloat height = countcoordinatesX(40);
            CGFloat top = SCREEN_HEIGHT - SafeAreaBottomHeight - countcoordinatesX(100) - height - NavigationBarHeight;
            CGRectMake(left, top, width, height);
        });
        [_share setTitle:@"检查更新" forState:UIControlStateNormal];
        [_share setTitle:@"检查更新" forState:UIControlStateHighlighted];
        [_share setTitleColor:kColor_Text_Black forState:UIControlStateNormal];
        [_share setTitleColor:kColor_Text_Black forState:UIControlStateHighlighted];
        [_share.titleLabel setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
        [_share setBackgroundImage:[UIColor createImageWithColor:kColor_BG] forState:UIControlStateNormal];
        [_share setBackgroundImage:[UIColor createImageWithColor:kColor_Line_Color] forState:UIControlStateHighlighted];
        [_share.layer setBorderColor:kColor_Text_Gary.CGColor];
        [_share.layer setBorderWidth:1.f / [UIScreen mainScreen].scale];
        [_share.layer setCornerRadius:5];
        [self.view addSubview:_share];
    }
    return _share;
}

- (UILabel *)version {
    if (!_version) {
        _version = [[UILabel alloc]init];
        _version.frame = ({
            CGFloat left = SCREEN_WIDTH / 4;
            CGFloat width = SCREEN_WIDTH - left * 2;
            CGFloat height = countcoordinatesX(32);
            CGFloat top = SCREEN_HEIGHT - SafeAreaBottomHeight - countcoordinatesX(40) - height - NavigationBarHeight;
            CGRectMake(left, top, width, height);
        });
        
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *appVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
        [_version setTextAlignment:NSTextAlignmentCenter];
        [_version setText:[@"V" stringByAppendingString: appVersion]];
        [_version setTextColor:[UIColor lightGrayColor]];
        [_version setFont:[UIFont systemFontOfSize:AdjustFont(10) weight:UIFontWeightLight]];
        [self.view addSubview:_version];
    }
    return _version;
}


@end
