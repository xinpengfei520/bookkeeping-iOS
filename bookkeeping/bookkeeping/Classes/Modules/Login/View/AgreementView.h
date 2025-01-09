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

@end

NS_ASSUME_NONNULL_END 