//
//  AFNManager.m
//  imiss-ios-master
//
//  Created by 郑业强 on 2018/10/27.
//  Copyright © 2018年 kk. All rights reserved.
//

#import "AFNManager.h"
#import <AFNetworking/AFNetworking.h>

#pragma mark - 声明
@interface AFNManager()

@end


#pragma mark - 实现
@implementation AFNManager

static AFHTTPSessionManager *_manager;


#pragma mark - get
+ (AFHTTPSessionManager *)manager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [AFHTTPSessionManager manager];
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
        _manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/xml", @"text/plain", nil];
        // post json 格式数据的时候加上这两句
        _manager.requestSerializer = [AFJSONRequestSerializer serializer];
    });
    return _manager;
}


#pragma mark - 请求
+ (void)POST:(NSString *)url params:(NSDictionary * _Nullable)params complete:(AFNManagerCompleteBlock)complete {
    [self POST:url params:params progress:nil complete:complete];
}

+ (void)POST:(NSString *)url params:(NSDictionary * _Nullable)params progress:(AFNManagerProgressBlock)progress complete:(AFNManagerCompleteBlock)complete {
    
    AFHTTPSessionManager *manager = [AFNManager manager];
    
    // 添加 Authorization 请求头
    NSString *authorization = [UserInfo getAuthorizationToken];
    if (authorization) {
        [manager.requestSerializer setValue:authorization forHTTPHeaderField:@"Authorization"];
    }
    
    [manager POST:url parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
        if (progress) {
            progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount, downloadProgress.fractionCompleted);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // 获取 header 中的 Authorization 并保存
        if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *headers = (NSHTTPURLResponse *)task.response;
            if (headers && [[headers allHeaderFields] isKindOfClass:[NSDictionary class]]
                && [[[headers allHeaderFields] allKeys]containsObject:@"Authorization"]) {
                NSString *authorization = [headers allHeaderFields][@"Authorization"];
                [UserInfo saveAuthorizationToken:authorization];
            }
        }
        
        if (complete) {
            APPResult *result = [APPResult mj_objectWithKeyValues:responseObject];
            result.status = HttpStatusSuccess;
            result.cache = CacheStatusSuccess;
            complete(result);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull err) {
        if (complete) {
            APPResult *result = [[APPResult alloc] init];
            result.data = nil;
            result.cache = CacheStatusFail;
            result.status = HttpStatusFail;
            result.msg = @"请求失败";
            complete(result);
        }
    }];
}

+ (void)POST:(NSString *)url params:(NSDictionary * _Nullable)params images:(NSArray<UIImage *> *)images progress:(AFNManagerProgressBlock)progress complete:(AFNManagerCompleteBlock)complete {
    AFHTTPSessionManager *manager = [self manager];
    // 添加 Authorization 请求头
    NSString *authorization = [UserInfo getAuthorizationToken];
    if (authorization) {
        [manager.requestSerializer setValue:authorization forHTTPHeaderField:@"Authorization"];
    }
    
    // 请求
    [manager POST:url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        // 图片
        if (images && [images count] > 0) {
            for (NSInteger index = 0; index < images.count; index++) {
                // 图片转数据
                NSString *imgName = [NSString stringWithFormat:@"image%ld", index];
                NSData *data = UIImagePNGRepresentation(images[index]);
                if (data == nil) {
                    data = UIImageJPEGRepresentation(images[index], 1.0);
                }
                // 添加参数
                [formData appendPartWithFileData:data name:@"file" fileName:imgName mimeType:@"image/png"];
            }
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        // 过程
        if (progress) {
            progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount, uploadProgress.fractionCompleted);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // 回调
        if (complete) {
            APPResult *result = [APPResult mj_objectWithKeyValues:responseObject];
            result.status = HttpStatusSuccess;
            result.cache = CacheStatusSuccess;
            complete(result);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // 回调
        if (complete) {
            APPResult *result = [[APPResult alloc] init];
            result.data = nil;
            result.cache = CacheStatusFail;
            result.status = HttpStatusFail;
            result.msg = @"请求失败";
            complete(result);
        }
    }];
}


@end
