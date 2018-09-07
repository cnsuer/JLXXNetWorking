//
//  JLXXRequestrConfig.h
//  Pods
//
//  Created by apple on 17/5/12.
//
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, JLXXNetworkReachabilityStatus) {
	JLXXNetworkReachabilityStatusUnknown          = -1,
	JLXXNetworkReachabilityStatusNotReachable     = 0,
	JLXXNetworkReachabilityStatusReachableViaWWAN = 1,
	JLXXNetworkReachabilityStatusReachableViaWiFi = 2,
};

FOUNDATION_EXPORT NSString * const JLXXNetworkingReachabilityDidChangeNotification;
FOUNDATION_EXPORT NSString * const JLXXNetworkingReachabilityNotificationStatusItem;
FOUNDATION_EXPORT NSString * const JLXXNetworkingUnauthorizedNotification;

@class AFSecurityPolicy;

@interface JLXXRequestConfig : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

/**
 Return a shared config object
 
 @return Return a shared config object
 */
+ (instancetype)sharedInstance;

/**
 *  如 http://api.mogujie.com
 */
@property (nonatomic, copy) NSString *baseURL;

/**
 *  当前的网络状态
 */
@property (nonatomic) JLXXNetworkReachabilityStatus networkStatus;

/**
 Security policy will be used by AFNetworking. See also `AFSecurityPolicy`.
 */
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;

/**
 SessionConfiguration will be used to initialize AFHTTPSessionManager. Default is nil
 */
@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;
/**
 processingQueue. AFN回调后的信息处理队列
 */
@property (nonatomic, strong, readonly) dispatch_queue_t processingQueue;
/**
 服务器响应数据的状态码的key ==>例如 code = 200 中的 code
 默认是code
 */
@property (nonatomic , copy) NSString *responseStatusCodeKey;
/**
 网络请求成功的状态码
 */
@property (nonatomic , strong) NSArray *successStatusCode;
/**
 网络请求结束的描述信息key
 */
@property (nonatomic , copy) NSString *responseDescriptionKey;
/**
 网络请求失败,原因为Unauthorized状态码,此时会发送一个通知,业务具体处理
 Unauthorized出现的情况:
 1:登录的token过期
 2:账户被禁用
 等情况
 */
@property (nonatomic , strong) NSArray<NSString *> *unauthorizedCodes;

/**
 是否加密
 */
@property (nonatomic , assign) BOOL isSecret;
/**
 秘钥.
 */
@property (nonatomic , copy) NSString *secretKey;
/**
 default params.
 */
@property (nonatomic, strong, readonly) NSDictionary *defaultParam;
/**
 Add new params to default params.
 
 @param param param
 */
- (void)appendDefaultParam:(NSDictionary *)param;
/**
 remove a params For key.
 
 @param key key
 */
- (void)removeParamFor:(NSString *)key;
@end

