/**
 * 请求结果
 * @author 郑业强 2018-10-
 */

#import <Foundation/Foundation.h>
// 业务成功码
#define BIZ_SUCCESS 0

#pragma mark - typeof
typedef NS_ENUM(NSInteger, CacheStatus) {
    CacheStatusSuccess = 200,       // 缓存成功
    CacheStatusDiskCache = 201,     // 硬盘缓存
    CacheStatusMemoryCache = 202,   // 内存缓存
    CacheStatusFail = 1001,         // 缓存失败
};

/**
 * HTTP 状态码：跟请求的网络状态有关，不由后端返回
 */
typedef NS_ENUM(NSInteger, HttpStatus) {
    HttpStatusSuccess = 200,       // 成功
    HttpStatusFail = 1001,         // 失败
    HttpStatusNoContent = 1002,    // API请求成功但返回数据不正确。如果回调数据验证函数返回值为NO，manager的状态就会是这个
    HttpStatusParamsError = 1003,  // 参数错误，此时manager不会调用API，因为参数验证是在调用API之前做的
    HttpStatusTimeout = 1004,      // 请求超时。ApiProxy设置的是20秒超时，具体超时时间的设置请自己去看ApiProxy的相关代码
    HttpStatusNoNetWork = 1005,    // 网络不通
};

/**
 * 封装统一的返回数据格式，cache 和 status 字段不是后端返回的，是我们自己添加的
 * {
 *  "msg": "success",
 *  "code": 0,
 *  “data”:null
 * }
 */
@interface APPResult : NSObject

@property (nonatomic, assign) CacheStatus cache;     // 缓存状态(非后端返回)
@property (nonatomic, assign) HttpStatus status;     // HTTP状态码(非后端返回)

@property (nonatomic, assign) NSInteger code;        // 响应码(后端返回)
@property (nonatomic, copy) NSString *msg;           // 响应描述(后端返回)
@property (nonatomic, strong) id data;               // 响应数据(后端返回)

@end
