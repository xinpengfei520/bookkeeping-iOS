//
//  UserInfoTokenTests.m
//  bookkeepingTests
//
//  JWT 规范化的存取契约：本地永远只存裸 token，Bearer 前缀只在
//  getAuthorizationHeader 拼一次。双前缀是服务端唯一会拒绝的形态，
//  这些用例锁死"怎么存都不会产生双前缀"。
//
//  测试会读写宿主 App 的真实 Keychain（模拟器环境），用例前后各清一次。
//

#import <XCTest/XCTest.h>

@interface UserInfo : NSObject
+ (void)saveAuthorizationToken:(NSString *)authorization;
+ (NSString *)getAuthorizationToken;
+ (NSString *)getAuthorizationHeader;
@end

@interface KKKeychain : NSObject
+ (void)removeKey:(NSString *)key;
@end

static NSString * const kTokenKey = @"AUTHORIZATION_TOKEN";     // 与 PINCache_Header.h 的宏一致


@interface UserInfoTokenTests : XCTestCase
@end

@implementation UserInfoTokenTests

- (void)setUp {
    [KKKeychain removeKey:kTokenKey];
}

- (void)tearDown {
    [KKKeychain removeKey:kTokenKey];
}

- (void)testBareTokenRoundTrip {
    [UserInfo saveAuthorizationToken:@"eyJ.abc.def"];
    XCTAssertEqualObjects([UserInfo getAuthorizationToken], @"eyJ.abc.def");
    XCTAssertEqualObjects([UserInfo getAuthorizationHeader], @"Bearer eyJ.abc.def");
}

- (void)testBearerPrefixIsStrippedOnSave {
    // 老服务端响应头就是这种形态
    [UserInfo saveAuthorizationToken:@"Bearer eyJ.abc.def"];
    XCTAssertEqualObjects([UserInfo getAuthorizationToken], @"eyJ.abc.def");
    XCTAssertEqualObjects([UserInfo getAuthorizationHeader], @"Bearer eyJ.abc.def");
}

- (void)testPrefixStripIsCaseInsensitiveAndWhitespaceTolerant {
    [UserInfo saveAuthorizationToken:@"  bearer   eyJ.abc.def  "];
    XCTAssertEqualObjects([UserInfo getAuthorizationToken], @"eyJ.abc.def");
}

- (void)testDoublePrefixCollapses {
    // "存的时候带前缀、发的时候又拼一次"的历史事故形态，必须收敛成单前缀
    [UserInfo saveAuthorizationToken:@"Bearer Bearer eyJ.abc.def"];
    XCTAssertEqualObjects([UserInfo getAuthorizationToken], @"eyJ.abc.def");
    XCTAssertEqualObjects([UserInfo getAuthorizationHeader], @"Bearer eyJ.abc.def");
}

- (void)testTokenNamedBearerIsPreserved {
    // 整个值就是 "Bearer"（畸形但可能出现）：剥完只剩空则保持原值不再剥，
    // 不应存出空 token
    [UserInfo saveAuthorizationToken:@"Bearer"];
    XCTAssertEqualObjects([UserInfo getAuthorizationToken], @"Bearer");
}

- (void)testEmptyAndNilAreIgnored {
    [UserInfo saveAuthorizationToken:@"eyJ.keep.me"];
    [UserInfo saveAuthorizationToken:@""];
    // 空串不应覆盖已有 token
    XCTAssertEqualObjects([UserInfo getAuthorizationToken], @"eyJ.keep.me");
}

- (void)testNoTokenMeansNilHeader {
    XCTAssertNil([UserInfo getAuthorizationToken]);
    XCTAssertNil([UserInfo getAuthorizationHeader]);
}

@end
