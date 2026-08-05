/**
 * 离线待办操作
 * 说明见 KKPendingBookOp.h
 */

#import "KKPendingBookOp.h"

static NSString * const kTypeKey  = @"type";
static NSString * const kModelKey = @"model";

@implementation KKPendingBookOp

+ (instancetype)opWithType:(KKBookOpType)type model:(BookDetailModel *)model {
    KKPendingBookOp *op = [[KKPendingBookOp alloc] init];
    op.type = type;
    op.model = model;
    return op;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _type = [coder decodeIntegerForKey:kTypeKey];
        _model = [coder decodeObjectForKey:kModelKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:_type forKey:kTypeKey];
    [coder encodeObject:_model forKey:kModelKey];
}

- (NSString *)description {
    NSString *name = _type == KKBookOpTypeAdd ? @"add" : (_type == KKBookOpTypeUpdate ? @"update" : @"delete");
    return [NSString stringWithFormat:@"<KKPendingBookOp %@ bookId=%ld>", name, (long)_model.bookId];
}

@end
