//
//  AFNManager.m
//  bookkeeping
//
//  Rewritten on NSURLSession in 2026-05 to drop the AFNetworking 4.0.1
//  dependency. Public API is identical to the previous implementation —
//  see AFNManager.h. The behavioural contract (Authorization refresh,
//  app_id header, TOKEN_EXPIRED notification, main-queue callbacks,
//  PNG→JPEG fallback) is documented in
//  docs/superpowers/specs/2026-05-07-phase1-dependency-cleanup-design.md
//

#import "AFNManager.h"

static NSString * const kAppIDHeader = @"app_id";
static NSString * const kAppIDValue  = @"638c2977f1b24ba0";

#pragma mark - Private declaration

@interface AFNManager () <NSURLSessionTaskDelegate>

+ (instancetype)shared;

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMapTable<NSURLSessionTask *, AFNManagerProgressBlock> *progressBlocks;
@property (nonatomic, strong) NSLock *progressLock;

@end

#pragma mark - Implementation

@implementation AFNManager

#pragma mark - Singleton

+ (instancetype)shared {
    static AFNManager *_shared;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _shared = [[AFNManager alloc] init];
    });
    return _shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
        cfg.timeoutIntervalForRequest  = 30.0;
        cfg.timeoutIntervalForResource = 60.0;
        cfg.URLCache = nil;
        _session = [NSURLSession sessionWithConfiguration:cfg
                                                 delegate:self
                                            delegateQueue:nil];
        _progressBlocks = [NSMapTable strongToStrongObjectsMapTable];
        _progressLock = [[NSLock alloc] init];
    }
    return self;
}

#pragma mark - Public class methods

+ (void)GET:(NSString *)url
     params:(NSDictionary *)params
   complete:(AFNManagerCompleteBlock)complete {

    AFNManager *m = [self shared];
    NSMutableURLRequest *req = [m buildGETRequestForURL:url params:params];
    if (req == nil) {
        [m deliverFailureToComplete:complete];
        return;
    }

    __block NSURLSessionDataTask *task = nil;
    task = [m.session dataTaskWithRequest:req
                        completionHandler:^(NSData *data, NSURLResponse *resp, NSError *error) {
        [m handleResponse:resp data:data error:error complete:complete forTask:task];
    }];
    [task resume];
}

+ (void)POST:(NSString *)url
      params:(NSDictionary *)params
    complete:(AFNManagerCompleteBlock)complete {
    [self POST:url params:params progress:nil complete:complete];
}

+ (void)POST:(NSString *)url
      params:(NSDictionary *)params
    progress:(AFNManagerProgressBlock)progress
    complete:(AFNManagerCompleteBlock)complete {

    AFNManager *m = [self shared];
    NSMutableURLRequest *req = [m buildJSONRequestForURL:url params:params];
    if (req == nil) {
        [m deliverFailureToComplete:complete];
        return;
    }

    __block NSURLSessionDataTask *task = nil;
    task = [m.session dataTaskWithRequest:req
                        completionHandler:^(NSData *data, NSURLResponse *resp, NSError *error) {
        [m handleResponse:resp data:data error:error complete:complete forTask:task];
    }];

    if (progress) {
        [m setProgressBlock:progress forTask:task];
    }
    [task resume];
}

+ (void)POST:(NSString *)url
      params:(NSDictionary *)params
      images:(NSArray<UIImage *> *)images
    progress:(AFNManagerProgressBlock)progress
    complete:(AFNManagerCompleteBlock)complete {

    AFNManager *m = [self shared];

    NSURL *u = [NSURL URLWithString:url];
    if (u == nil) {
        [m deliverFailureToComplete:complete];
        return;
    }

    NSString *boundary = [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
    NSData *body = [m buildMultipartBodyWithParams:params images:images boundary:boundary];

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:u];
    req.HTTPMethod = @"POST";
    [req setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary]
forHTTPHeaderField:@"Content-Type"];
    [m applyCommonHeaders:req];

    __block NSURLSessionUploadTask *task = nil;
    task = [m.session uploadTaskWithRequest:req
                                   fromData:body
                          completionHandler:^(NSData *data, NSURLResponse *resp, NSError *error) {
        [m handleResponse:resp data:data error:error complete:complete forTask:task];
    }];

    if (progress) {
        [m setProgressBlock:progress forTask:task];
    }
    [task resume];
}

#pragma mark - Request building

- (NSMutableURLRequest *)buildGETRequestForURL:(NSString *)url params:(NSDictionary *)params {
    NSURLComponents *comp = [NSURLComponents componentsWithString:url];
    if (comp == nil) {
        return nil;
    }
    if (params.count > 0) {
        NSMutableArray<NSURLQueryItem *> *items = [NSMutableArray array];
        [params enumerateKeysAndObjectsUsingBlock:^(id k, id v, BOOL *stop) {
            [items addObject:[NSURLQueryItem queryItemWithName:[NSString stringWithFormat:@"%@", k]
                                                         value:[NSString stringWithFormat:@"%@", v]]];
        }];
        comp.queryItems = items;
    }
    NSURL *u = comp.URL;
    if (u == nil) {
        return nil;
    }

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:u];
    req.HTTPMethod = @"GET";
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [self applyCommonHeaders:req];
    return req;
}

/// app_id + Authorization。Authorization 统一走 `Bearer <裸 JWT>`，前缀只在这里拼一次。
- (void)applyCommonHeaders:(NSMutableURLRequest *)req {
    [req setValue:kAppIDValue forHTTPHeaderField:kAppIDHeader];
    NSString *auth = [UserInfo getAuthorizationHeader];
    if (auth) {
        [req setValue:auth forHTTPHeaderField:@"Authorization"];
    }
}

- (NSMutableURLRequest *)buildJSONRequestForURL:(NSString *)url params:(NSDictionary *)params {
    NSURL *u = [NSURL URLWithString:url];
    if (u == nil) {
        return nil;
    }

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:u];
    req.HTTPMethod = @"POST";
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [self applyCommonHeaders:req];

    if (params) {
        NSError *err = nil;
        NSData *bodyData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&err];
        if (err || bodyData == nil) {
            return nil;
        }
        req.HTTPBody = bodyData;
    }
    return req;
}

- (NSData *)buildMultipartBodyWithParams:(NSDictionary *)params
                                  images:(NSArray<UIImage *> *)images
                                boundary:(NSString *)boundary {
    NSMutableData *body = [NSMutableData data];
    NSData *crlf = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];

    [params enumerateKeysAndObjectsUsingBlock:^(id k, id v, BOOL *stop) {
        NSString *key = [NSString stringWithFormat:@"%@", k];
        NSString *val = [NSString stringWithFormat:@"%@", v];
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[val dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:crlf];
    }];

    for (NSInteger i = 0; i < (NSInteger)images.count; i++) {
        UIImage *image = images[i];
        // JPEG 优先：避免 PNG 对照片体积过大（前 AFN 实现用 PNG 优先 + JPEG-1.0 fallback，
        // 在生产 nginx 默认 1MB body 上限下从未真正工作过——头像就是这条路径）。
        NSString *mime = @"image/jpeg";
        NSString *ext = @"jpg";
        NSData *data = UIImageJPEGRepresentation(image, 0.85);
        if (data == nil) {
            data = UIImagePNGRepresentation(image);
            mime = @"image/png";
            ext = @"png";
        }
        if (data == nil) {
            continue; // skip un-encodable image
        }
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"image%ld.%@\"\r\n", (long)i, ext] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mime] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:data];
        [body appendData:crlf];
    }

    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    return body;
}

// 收掉所有窗口上的 JGProgressHUD（必须在主线程调用）
+ (void)dismissAllProgressHUDs {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) {
            continue;
        }
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            for (JGProgressHUD *hud in [JGProgressHUD allProgressHUDsInViewHierarchy:window]) {
                [hud dismiss];
            }
        }
    }
}

#pragma mark - Progress map

- (void)setProgressBlock:(AFNManagerProgressBlock)block forTask:(NSURLSessionTask *)task {
    AFNManagerProgressBlock copied = [block copy];
    [_progressLock lock];
    [_progressBlocks setObject:copied forKey:task];
    [_progressLock unlock];
}

- (void)removeProgressBlockForTask:(NSURLSessionTask *)task {
    if (task == nil) return;
    [_progressLock lock];
    [_progressBlocks removeObjectForKey:task];
    [_progressLock unlock];
}

#pragma mark - Response handling

- (void)deliverFailureToComplete:(AFNManagerCompleteBlock)complete {
    if (complete == nil) return;
    APPResult *r = [[APPResult alloc] init];
    r.data = nil;
    r.status = HttpStatusFail;
    r.cache = CacheStatusFail;
    r.msg = KKLocalized(@"请求失败");
    dispatch_async(dispatch_get_main_queue(), ^{
        complete(r);
    });
}

- (void)handleResponse:(NSURLResponse *)response
                  data:(NSData *)data
                 error:(NSError *)error
              complete:(AFNManagerCompleteBlock)complete
               forTask:(NSURLSessionTask *)task {

    // 1) Refresh Authorization header from response (if present)
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSDictionary *headers = ((NSHTTPURLResponse *)response).allHeaderFields;
        if ([headers isKindOfClass:[NSDictionary class]] &&
            [headers.allKeys containsObject:@"Authorization"]) {
            id newAuth = headers[@"Authorization"];
            if ([newAuth isKindOfClass:[NSString class]] && [(NSString *)newAuth length] > 0) {
                [UserInfo saveAuthorizationToken:(NSString *)newAuth];
                [UserInfo saveAuthorizationTimestamp];
            }
        }
    }

    NSURL *requestURL = task.originalRequest.URL;
    NSInteger statusCode = [response isKindOfClass:[NSHTTPURLResponse class]]
        ? ((NSHTTPURLResponse *)response).statusCode : -1;

    // 2) Failure path
    if (error) {
        NSLog(@"[AFNManager] transport error url=%@ status=%ld error=%@",
              requestURL, (long)statusCode, error);
        [self removeProgressBlockForTask:task];
        [self deliverFailureToComplete:complete];
        return;
    }

    // 3) JSON decode → APPResult (preserves MJExtension call)
    NSError *jsonErr = nil;
    id obj = nil;
    if (data.length > 0) {
        obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonErr];
    }
    APPResult *result = obj ? [APPResult mj_objectWithKeyValues:obj] : nil;
    if (result == nil) {
        NSString *snippet = data.length > 0
            ? [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, MIN((NSUInteger)512, data.length))]
                                    encoding:NSUTF8StringEncoding]
            : @"<empty>";
        NSLog(@"[AFNManager] decode failed url=%@ status=%ld jsonError=%@ bodyLen=%lu bodyHead=%@",
              requestURL, (long)statusCode, jsonErr,
              (unsigned long)data.length, snippet ?: @"<binary>");
        [self removeProgressBlockForTask:task];
        [self deliverFailureToComplete:complete];
        return;
    }

    // 3.5) 登录/刷新类接口的标准令牌字段：响应体 `token` 是裸 JWT，优先于响应头。
    //      服务端 v1.1.0 起响应头 Authorization 也已是裸值，两条路径存下来的都是裸 token。
    if (result.token.length > 0) {
        [UserInfo saveAuthorizationToken:result.token];
        [UserInfo saveAuthorizationTimestamp];
        [UserInfo saveAuthorizationExpiresIn:result.expiresIn];
    }

    // 4) Token expired path — match prior contract: post notification, do NOT call complete:
    if (result.code == TOKEN_EXPIRED) {
        [self removeProgressBlockForTask:task];
        dispatch_async(dispatch_get_main_queue(), ^{
            // complete 不回调意味着调用方请求前 show 的 HUD 永远等不到 hideHUD ——
            // 在这里统一把全窗口的 JGProgressHUD 收掉，否则转圈会一直盖在登录页下面。
            [AFNManager dismissAllProgressHUDs];
            [[NSNotificationCenter defaultCenter] postNotificationName:MINE_TOKEN_EXPIRED object:nil];
        });
        return;
    }

    // 5) Success path
    result.status = HttpStatusSuccess;
    result.cache  = CacheStatusSuccess;
    [self removeProgressBlockForTask:task];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (complete) {
            complete(result);
        }
    });
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {

    [_progressLock lock];
    AFNManagerProgressBlock block = [_progressBlocks objectForKey:task];
    [_progressLock unlock];

    if (block == nil) return;

    CGFloat pct = (totalBytesExpectedToSend > 0)
        ? (CGFloat)totalBytesSent / (CGFloat)totalBytesExpectedToSend
        : 0;

    dispatch_async(dispatch_get_main_queue(), ^{
        block((CGFloat)totalBytesSent, (CGFloat)totalBytesExpectedToSend, pct);
    });
}

@end
