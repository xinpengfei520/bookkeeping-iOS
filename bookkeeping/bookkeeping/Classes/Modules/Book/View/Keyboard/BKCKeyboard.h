/**
 * 键盘
 * @author 郑业强 2018-12-18 创建文件
 */

#import "BaseView.h"
#import "BookDetailModel.h"

NS_ASSUME_NONNULL_BEGIN


#pragma mark - typedef
/// @param price    键盘上输入的金额。**币种是 currency**：选了外币时这是外币原始金额，
///                 换算成人民币由 BookController 负责（price 字段永远是人民币）。
/// @param currency 币种代码，人民币时为 CNY
/// @param rate     1 单位 currency 兑人民币的汇率，人民币时为 0
typedef void (^BookComplete)(NSString *price, NSString *mark, NSDate *date, NSString *currency, CGFloat rate);
/// 币种或记账日期变化时上抛，由 BookController 去拉 GET /book/rates
typedef void (^BookRateRequest)(NSString *currency, NSDate *date);

#pragma mark - 声明
@interface BKCKeyboard : BaseView

@property (nonatomic, strong) NSMutableString *money;
@property (nonatomic, copy  ) BookComplete complete;
@property (nonatomic, copy  ) BookRateRequest rateRequest;
@property (nonatomic, strong) BookDetailModel *model;
/// 当前选中的币种，默认 CNY
@property (nonatomic, copy, readonly) NSString *currency;

+ (instancetype)init;

- (void)show;
- (void)hide;
- (void)setMark:(MarkModel *)model;
/// 汇率回填。rate <= 0 表示这次没取到，键盘会退回人民币并提示，绝不静默按 1:1 记账。
/// @param stale 服务端返回的是缓存中的旧汇率，需要提醒用户确认
- (void)setExchangeRate:(CGFloat)rate forCurrency:(NSString *)currency stale:(BOOL)stale;

@end

NS_ASSUME_NONNULL_END
