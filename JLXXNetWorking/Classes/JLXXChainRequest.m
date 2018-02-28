//
//  JLXXChainRequest.m
//  sisitv_ios
//
//  Created by apple on 16/12/15.
//  Copyright © 2016年 JLXX--JLXX. All rights reserved.
//

#import "JLXXChainRequest.h"
#import "JLXXRequest.h"

@interface JLXXChainRequestManager()

@property (strong, nonatomic) NSMutableArray<JLXXChainRequest *> *requestArray;

@end
@implementation JLXXChainRequestManager

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

- (void)addChainRequest:(JLXXChainRequest *)request {
    @synchronized(self) {
        [_requestArray addObject:request];
    }
}

- (void)removeChainRequest:(JLXXChainRequest *)request {
    @synchronized(self) {
        [_requestArray removeObject:request];
    }
}

@end

@interface JLXXChainRequest()<JLXXRequestDelegate>

@property (strong, nonatomic) NSMutableArray<JLXXRequest *> *requestArray;
@property (strong, nonatomic) NSMutableArray<JLXXChainCallback> *requestCallbackArray;
@property (assign, nonatomic) NSUInteger nextRequestIndex;
@property (strong, nonatomic) JLXXChainCallback emptyCallback;

@end

@implementation JLXXChainRequest

- (instancetype)init {
    self = [super init];
    if (self) {
        _nextRequestIndex = 0;
        _requestArray = [NSMutableArray array];
        _requestCallbackArray = [NSMutableArray array];
        _emptyCallback = ^(JLXXChainRequest *chainRequest, JLXXRequest *baseRequest) {
            // do nothing
        };
    }
    return self;
}

- (void)addRequest:(JLXXRequest *)request callback:(JLXXChainCallback)callback {
    [_requestArray addObject:request];
    if (callback != nil) {
        [_requestCallbackArray addObject:callback];
    } else {
        [_requestCallbackArray addObject:_emptyCallback];
    }
}

- (void)start {
    if (_nextRequestIndex > 0) {
#ifdef DEBUG
        NSLog(@"Error! Chain request has already started.");
#else
#endif
        return;
    }
    
    if ([_requestArray count] > 0) {
        [self startNextRequest];
        [[JLXXChainRequestManager sharedInstance] addChainRequest:self];
    } else {
#ifdef DEBUG
        NSLog(@"Error! Chain request array is empty.");
#else
#endif
    }
}

- (BOOL)startNextRequest {
    if (_nextRequestIndex < [_requestArray count]) {
        JLXXRequest *request = _requestArray[_nextRequestIndex];
        _nextRequestIndex++;
        request.delegate = self;
        [request clearCompletionBlock];
        [request start];
        return YES;
    } else {
        return NO;
    }
}

- (void)stop {
    [self clearRequest];
    [[JLXXChainRequestManager sharedInstance] removeChainRequest:self];
}

- (NSArray<JLXXRequest *> *)requestArray {
    return _requestArray;
}

#pragma mark - Network Request Delegate

- (void)clearRequest {
    NSUInteger currentRequestIndex = _nextRequestIndex - 1;
    if (currentRequestIndex < [_requestArray count]) {
        JLXXRequest *request = _requestArray[currentRequestIndex];
        [request stop];
    }
    [_requestArray removeAllObjects];
    [_requestCallbackArray removeAllObjects];
}
-(void)requestFinished:(__kindof JLXXRequest *)request{
    NSUInteger currentRequestIndex = _nextRequestIndex - 1;
    JLXXChainCallback callback = _requestCallbackArray[currentRequestIndex];
    callback(self, request);
    if (![self startNextRequest]) {
        if ([_delegate respondsToSelector:@selector(chainRequestFinished:)]) {
            [_delegate chainRequestFinished:self];
        }
        [[JLXXChainRequestManager sharedInstance] removeChainRequest:self];
    }
}

- (void)requestFailed:(JLXXRequest *)request {
    if ([_delegate respondsToSelector:@selector(chainRequestFailed:failedBaseRequest:)]) {
        [_delegate chainRequestFailed:self failedBaseRequest:request];
    }
    [[JLXXChainRequestManager sharedInstance] removeChainRequest:self];

}
@end
