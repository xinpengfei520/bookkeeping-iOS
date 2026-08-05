/**
 * 离线待办操作 —— 记账的增 / 改 / 删在网络不通时排队，联网后按序补发
 *
 * 背景：1.0.11 只把「新增」做了离线闭环，改和删失败时仅弹 toast，
 * 导致本地与服务端不一致（删除后记录会"复活"、修改重启后回滚）。
 * 现在三种操作统一进这个队列（NSUserDefaults 的 PIN_BOOK_FAILED）。
 *
 * 入队时按 bookId 合并，避免同一条记录堆积互相矛盾的操作，语义见
 * NSUserDefaults+Extension 的 enqueuePendingBookOp:。
 */

#import <Foundation/Foundation.h>
#import "BookDetailModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, KKBookOpType) {
    KKBookOpTypeAdd    = 0,     // POST /book/detail/save
    KKBookOpTypeUpdate = 1,     // POST /book/detail/update
    KKBookOpTypeDelete = 2,     // POST /book/detail/delete
};

@interface KKPendingBookOp : NSObject <NSCoding>

@property (nonatomic, assign) KKBookOpType type;
@property (nonatomic, strong) BookDetailModel *model;

+ (instancetype)opWithType:(KKBookOpType)type model:(BookDetailModel *)model;

@end

NS_ASSUME_NONNULL_END
