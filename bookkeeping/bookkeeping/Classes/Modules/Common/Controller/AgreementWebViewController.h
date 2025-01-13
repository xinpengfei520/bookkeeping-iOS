#import "BaseViewController.h"

typedef NS_ENUM(NSInteger, AgreementType) {
    AgreementTypeUserAgreement = 0,  // 用户协议
    AgreementTypePrivacyPolicy = 1   // 隐私政策
};

NS_ASSUME_NONNULL_BEGIN

@interface AgreementWebViewController : BaseViewController

@property (nonatomic, assign) AgreementType type;

@end

NS_ASSUME_NONNULL_END 