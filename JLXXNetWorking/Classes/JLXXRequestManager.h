//
//  JLXXRequestManager.h
//  sisitv_ios
//
//  Created by apple on 16/12/5.
//  Copyright © 2016年 JLXX--JLXX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JLXXRequest;

@class JLXXRequestConfig;

@interface JLXXRequestManager : NSObject


+ (instancetype)sharedInstance;

/**
 *  正在发送的请求们，里面是一些 NSURLSessionDataTask
 */
@property (nonatomic, readonly) NSArray *runningTasks;


/**
 Add request to session and start request.
 
 @param request 网络请求的接口和请求方式等的包装
 */
- (void)addRequest:(JLXXRequest *)request ;


///  Cancel a request that was previously added.
- (void)cancelRequest:(JLXXRequest *)request;

///  Cancel all requests that were previously added.
- (void)cancelAllRequests;


@end

