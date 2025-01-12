#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AgreementViewDelegate <NSObject>
- (void)agreementViewDidChangeState:(BOOL)isSelected;
- (void)agreementViewDidTapUserAgreement;
- (void)agreementViewDidTapPrivacyAgreement;
@end

@interface AgreementView : UIView

@property (nonatomic, weak) id<AgreementViewDelegate> delegate;
@property (nonatomic, assign) BOOL isSelected;
/**
 * 是否显示注册提示，验证码登录需要显示，密码登录不需要显示
 */
@property (nonatomic, assign) BOOL isShowRegisterTips;

- (instancetype)initWithShowRegisterTips:(BOOL)showRegisterTips;

@end

NS_ASSUME_NONNULL_END 
