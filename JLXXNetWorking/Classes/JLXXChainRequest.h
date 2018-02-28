//
//  JLXXChainRequest.h
//  sisitv_ios
//
//  Created by apple on 16/12/15.
//  Copyright © 2016年 JLXX--JLXX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class JLXXRequest,JLXXChainRequest;

///  The JLXXChainRequestDelegate protocol defines several optional methods you can use
///  to receive network-related messages. All the delegate methods will be called
///  on the main queue. Note the delegate methods will be called when all the requests
///  of chain request finishes.
@protocol JLXXChainRequestDelegate <NSObject>

@optional
///  Tell the delegate that the chain request has finished successfully.
///
///  @param chainRequest The corresponding chain request.
- (void)chainRequestFinished:(JLXXChainRequest *)chainRequest;

///  Tell the delegate that the chain request has failed.
///
///  @param chainRequest The corresponding chain request.
///  @param request      First failed request that causes the whole request to fail.
- (void)chainRequestFailed:(JLXXChainRequest *)chainRequest failedBaseRequest:(JLXXRequest*)request;

@end

///  JLXXChainRequestManager handles chain request management. It keeps track of all
///  the chain requests.
@interface JLXXChainRequestManager : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

///  Get the shared chain request Manager.
+ (instancetype)sharedInstance;

///  Add a chain request.
- (void)addChainRequest:(JLXXChainRequest *)request;

///  Remove a previously added chain request.
- (void)removeChainRequest:(JLXXChainRequest *)request;

@end

typedef void (^JLXXChainCallback)(JLXXChainRequest *chainRequest, JLXXRequest *request);

///  JLXXChainRequest can be used to chain several JLXXRequest so that one will only starts after another finishes.
///  Note that when used inside JLXXChainRequest, a single JLXXRequest will have its own callback and delegate
///  cleared, in favor of the batch request callback.
@interface JLXXChainRequest : NSObject

///  All the requests are stored in this array.
- (NSArray<JLXXRequest *> *)requestArray;

///  The delegate object of the chain request. Default is nil.
@property (nonatomic, weak, nullable) id<JLXXChainRequestDelegate> delegate;

///  Start the chain request, adding first request in the chain to request queue.
- (void)start;

///  Stop the chain request. Remaining request in chain will be cancelled.
- (void)stop;

///  Add request to request chain.
///
///  @param request  The request to be chained.
///  @param callback The finish callback
- (void)addRequest:(JLXXRequest *)request callback:(nullable JLXXChainCallback)callback;


@end
NS_ASSUME_NONNULL_END
