#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AgreementWebViewController : UIViewController

@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, copy) NSString *navTitle;
@property (nonatomic, strong, readonly) UIButton *leftButton;

- (instancetype)initWithTitle:(NSString *)title url:(NSString *)url;

@end

NS_ASSUME_NONNULL_END 