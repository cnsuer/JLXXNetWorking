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
@interface JLXXBatchRequest : NSObject

///  All the requests are stored in this array.
@property (nonatomic, strong, readonly) NSArray<JLXXRequest *> *requestArray;

///  The success callback. Note this will be called only if all the requests are finished.
///  This block will be called on the main queue.
@property (nonatomic, copy, nullable) void (^successCompletionBlock)(JLXXBatchRequest *);

///  The failure callback. Note this will be called if one of the requests fails.
///  This block will be called on the main queue.
@property (nonatomic, copy, nullable) void (^failureCompletionBlock)(JLXXBatchRequest *);

///  Tag can be used to identify batch request. Default value is 0.
@property (nonatomic) NSInteger tag;

///  The first request that failed (and causing the batch request to fail).
@property (nonatomic, strong, readonly, nullable) JLXXRequest *failedRequest;

///  Creates a `JLXXBatchRequest` with a bunch of requests.
///
///  @param requestArray requests useds to create batch request.
///
- (instancetype)initWithRequestArray:(NSArray<JLXXRequest *> *)requestArray;

///  Convenience method to start the batch request with block callbacks.
- (void)startWithCompletionBlockWithSuccess:(nullable void (^)(JLXXBatchRequest *batchRequest))success
                                    failure:(nullable void (^)(JLXXBatchRequest *batchRequest))failure;

///  Stop all the requests of the batch request.
- (void)stop;

///  Nil out both success and failure callback blocks.
- (void)clearCompletionBlock;

@end

NS_ASSUME_NONNULL_END
