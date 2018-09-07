//
//  JLXXBatchRequest.h
//  sisitv_ios
//
//  Created by apple on 16/12/8.
//  Copyright © 2016年 JLXX--JLXX. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@class JLXXRequest;
@class JLXXBatchRequest;

///  JLXXBatchRequestManager handles batch request management. It keeps track of all
///  the batch requests.
@interface JLXXBatchRequestManager : NSObject

///  Get the shared batch request agent.
+ (instancetype )sharedInstance;

///  Add a batch request.
- (void)addBatchRequest:(JLXXBatchRequest *)request;

///  Remove a previously added batch request.
- (void)removeBatchRequest:(JLXXBatchRequest *)request;

@end


//  JLXXBatchRequest can be used to batch several JLXXRequest. Note that when used inside JLXXBatchRequest, a single
///  JLXXRequest will have its own callback and delegate cleared, in favor of the batch request callback.

///  这里常见于一个页面有多个网络请求,下拉刷新的时候全部请求,加载更多的时候,只加载某一个或几个请求.
///  所以sometimesRequests里的request,在上拉加载时,不会请求

@interface JLXXBatchRequest : NSObject

///  Creates a `JLXXBatchRequest` with a bunch of requests.
///
///  @param requestArray requests useds to create batch request.
///
- (instancetype)initWithRequestArray:(NSArray<JLXXRequest *> *)requestArray;

/// isRefresh 本次请求是否是刷新
- (instancetype)initWithAlwaysRequests:(NSArray<JLXXRequest *> *)alwaysRequests refreshRequests:(NSArray<JLXXRequest *> *)refreshRequests isRefresh:(BOOL)isRefresh;

///  All the requests are stored in this array.
@property (nonatomic, strong, readonly) NSMutableArray<JLXXRequest *> *requestArray;

/// 本次请求是否是刷新
@property (nonatomic , assign, readonly) BOOL isRefresh;

@property (nonatomic, strong, readonly) NSArray<JLXXRequest *> *refreshRequests;

///  The requests that successed (and causing the batch request to sucess).
@property (nonatomic, strong, readonly, nullable) NSMutableArray<JLXXRequest *> *successRequests;

///  The requests request that failed (and causing the batch request to fail).
@property (nonatomic, strong, readonly, nullable) NSMutableArray<JLXXRequest *> *failedRequests;

///  The callback. Note this will be called only if all the requests are finished(some success,some failer).
///  This block will be called on the main queue.
@property (nonatomic, copy, nullable) void (^completionBlock)(JLXXBatchRequest *);

///  The failure callback. Note this will be called if all of the requests fails.
///  This block will be called on the main queue.
@property (nonatomic, copy, nullable) void (^failureCompletionBlock)(JLXXBatchRequest *);

///  Convenience method to start the batch request with block callbacks.
- (void)startWithCompletionBlockWithCallBack:(void (^)(JLXXBatchRequest *batchRequest))callBack
						   allRequestFailure:(void (^)(JLXXBatchRequest *batchRequest))failure;

- (BOOL)requestInRefreshRequestsArray:(JLXXRequest *)request;
- (BOOL)requestInSuccessRequestArray:(JLXXRequest *)request;
- (BOOL)requestInFailerRequestArray:(JLXXRequest *)request;
- (BOOL)request:(JLXXRequest *)request inRequestArray:(NSArray *)requestArray;

///  Stop all the requests of the batch request.
- (void)stop;

///  Nil out both success and failure callback blocks.
- (void)clearCompletionBlock;

@end

NS_ASSUME_NONNULL_END
