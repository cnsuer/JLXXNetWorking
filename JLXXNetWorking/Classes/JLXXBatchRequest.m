//
//  JLXXBatchRequest.m
//  sisitv_ios
//
//  Created by apple on 16/12/8.
//  Copyright © 2016年 JLXX--JLXX. All rights reserved.
//

#import "JLXXBatchRequest.h"
#import "JLXXRequest.h"

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

@implementation JLXXBatchRequest

-(instancetype)initWithRequestArray:(NSArray<JLXXRequest *> *)requestArray{
    if (self) {
        _requestArray = [requestArray copy];
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
	
	[[JLXXBatchRequestManager sharedInstance] addBatchRequest:self];
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
    [self clearRequest];
    [[JLXXBatchRequestManager sharedInstance] removeBatchRequest:self];
}

- (void)clearRequest {
    for (JLXXRequest * request in _requestArray) {
        [request stop];
    }
    [self clearCompletionBlock];
}

- (void)clearCompletionBlock {
    // nil out to break the retain cycle.
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
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
    @synchronized(self) {
        _finishedCount++;
		[_successRequests addObject:request];
    }
    if (_finishedCount == _requestArray.count) {

        if (_successCompletionBlock) {
            _successCompletionBlock(self);
        }
        // Clear
        [self clearCompletionBlock];
        [[JLXXBatchRequestManager sharedInstance] removeBatchRequest:self];
    }
}

- (void)requestFailed:(JLXXRequest *)request {
    @synchronized(self) {
        _finishedCount++;
		[_failedRequests addObject:request];
    }
    if (_finishedCount == _requestArray.count) {
        // Callback
        if (_failureCompletionBlock) {
            _failureCompletionBlock(self);
        }
        // Clear
        [self clearCompletionBlock];
        [[JLXXBatchRequestManager sharedInstance] removeBatchRequest:self];
    }
}

- (void)dealloc {
    [self clearRequest];
}

@end
