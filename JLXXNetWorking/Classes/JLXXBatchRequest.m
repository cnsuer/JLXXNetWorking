//
//  JLXXBatchRequest.m
//  sisitv_ios
//
//  Created by apple on 16/12/8.
//  Copyright © 2016年 JLXX--JLXX. All rights reserved.
//

#import "JLXXBatchRequest.h"
#import "JLXXRequest.h"

#import <pthread/pthread.h>

#define BatchRequestLock() pthread_mutex_lock(&_lock)
#define BatchRequestUnlock() pthread_mutex_unlock(&_lock)

@interface JLXXBatchRequestManager ()

@property (strong, nonatomic) NSMutableArray<JLXXBatchRequest *> *requestArray;

@end

@implementation JLXXBatchRequestManager

+(instancetype)sharedInstance{
	
	static id sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});
	return sharedInstance;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_requestArray = [NSMutableArray array];
	}
	return self;
}

- (void)addBatchRequest:(JLXXBatchRequest *)request {
	@synchronized(self) {
		[_requestArray addObject:request];
	}
}

- (void)removeBatchRequest:(JLXXBatchRequest *)request {
	@synchronized(self) {
		[_requestArray removeObject:request];
	}
}

@end

@interface JLXXBatchRequest ()<JLXXRequestDelegate>

@property (nonatomic) NSInteger finishedCount;

@end

@implementation JLXXBatchRequest{
	pthread_mutex_t _lock;
}

-(instancetype)initWithRequestArray:(NSArray<JLXXRequest *> *)requestArray{
	if (self = [super init]) {
		_requestArray = [requestArray mutableCopy];
		_finishedCount = 0;
		for (JLXXRequest * request in _requestArray) {
			if (![request isKindOfClass:[JLXXRequest class]]) {
#ifdef DEBUG
				NSLog(@"Error, request item must be JLXXRequest instance.");
#else
#endif
				return nil;
			}
		}
	}
	return self;
}

-(instancetype)initWithAlwaysRequests:(NSArray<JLXXRequest *> *)alwaysRequests refreshRequests:(NSArray<JLXXRequest *> *)refreshRequests{
	if (self = [super init]) {
		
		_refreshRequests = [refreshRequests copy];
		
		_requestArray = [alwaysRequests mutableCopy];
		[_requestArray addObjectsFromArray:refreshRequests];
		
		_finishedCount = 0;
		for (JLXXRequest * request in _requestArray) {
			if (![request isKindOfClass:[JLXXRequest class]]) {
#ifdef DEBUG
				NSLog(@"Error, request item must be JLXXRequest instance.");
#else
#endif
				return nil;
			}
		}
	}
	return self;
}

- (void)start {
	if (_finishedCount > 0) {
#ifdef DEBUG
		NSLog(@"Error! Batch request has already started.");
#else
#endif
		return;
	}
	_successRequests = [NSMutableArray array];
	_failedRequests = [NSMutableArray array];
	pthread_mutex_init(&_lock, NULL);
	
	[[JLXXBatchRequestManager sharedInstance] addBatchRequest:self];
	
	//不是Refresh,且refreshRequests有值
	if (!self.isRefresh && _refreshRequests.count>0) {
		__weak typeof(self) ws = self;
		[_requestArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(JLXXRequest * _Nonnull request, NSUInteger idx, BOOL * _Nonnull stop) {
			//需要删除不执行的requests
			if ([ws.refreshRequests containsObject:request]) {
				[ws.requestArray removeObject:request];
			}
		}];
	}
	
	for (JLXXRequest * request in _requestArray) {
		request.delegate = self;
		[request clearCompletionBlock];
		[request start];
	}
}

- (void)startWithCompletionBlockWithSuccess:(void (^)(JLXXBatchRequest *batchRequest))success
									failure:(void (^)(JLXXBatchRequest *batchRequest))failure {
	[self setCompletionBlockWithSuccess:success failure:failure];
	[self start];
}

- (void)setCompletionBlockWithSuccess:(void (^)(JLXXBatchRequest *batchRequest))success
							  failure:(void (^)(JLXXBatchRequest *batchRequest))failure {
	self.successCompletionBlock = success;
	self.failureCompletionBlock = failure;
}
- (void)stop {
	for (JLXXRequest * request in _requestArray) {
		[request stop];
	}
	
	[self clearCompletionBlock];
	
	[[JLXXBatchRequestManager sharedInstance] removeBatchRequest:self];
}

- (void)clearCompletionBlock {
	// nil out to break the retain cycle.
	self.successCompletionBlock = nil;
	self.failureCompletionBlock = nil;
	
	//clearRequest
	_successRequests = nil;
	_failedRequests = nil;
	_refreshRequests = nil;
	_requestArray = nil;
}

-(BOOL)requestInRefreshRequestsArray:(JLXXRequest *)request{
	return [self request:request inRequestArray:_refreshRequests];
}

-(BOOL)requestInSuccessRequestArray:(JLXXRequest *)request{
	return [self request:request inRequestArray:_successRequests];
}

-(BOOL)requestInFailerRequestArray:(JLXXRequest *)request{
	return [self request:request inRequestArray:_failedRequests];
}

-(BOOL)request:(JLXXRequest *)request inRequestArray:(NSArray *)requestArray{
	BOOL isIn = NO;
	for (JLXXRequest *re in requestArray) {
		if ([request isEqual:re]) { isIn = YES; break; }
	}
	return isIn;
}

#pragma mark - Network Request Delegate

- (void)requestFinished:(__kindof JLXXRequest *)request{
	BatchRequestUnlock();
	[_successRequests addObject:request];
	self.finishedCount++;
	BatchRequestLock();
}

- (void)requestFailed:(JLXXRequest *)request {
	BatchRequestUnlock();
	[_failedRequests addObject:request];
	self.finishedCount++;
	BatchRequestLock();
}

-(void)setFinishedCount:(NSInteger)finishedCount{
	_finishedCount = finishedCount;
	
	if (_finishedCount != _requestArray.count){ return ;}
	
	//为什么在主队列clearCompletionBlock和removeBatchRequest?
	//因为执行setFinishedCount这个方法的线程不是主线程所以,执行CompletionBlock与clear、remove不确定谁先执行完毕,有可能先执行clear、remove,从而导致CompletionBlock中的request为nil,造成取不到数据的错误,所以统一在主队列里执行了

	__weak typeof(self) ws = self;
	if(_failedRequests.count  == _finishedCount) {
		// Callback
		dispatch_async(dispatch_get_main_queue(), ^{
			if (ws.failureCompletionBlock) {
				ws.failureCompletionBlock(ws);
			}
		});
	}else {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (ws.successCompletionBlock) {
				ws.successCompletionBlock(ws);
			}
		});
	}
	// Clear
	dispatch_async(dispatch_get_main_queue(), ^{
		[ws clearCompletionBlock];
		[[JLXXBatchRequestManager sharedInstance] removeBatchRequest:ws];
	});

}
- (void)dealloc {
	[self clearCompletionBlock];
}

@end

