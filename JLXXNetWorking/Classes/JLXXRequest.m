//
//  JLXXRequest.m
//  sisitv_ios
//
//  Created by apple on 16/12/6.
//  Copyright © 2016年 JLXX--JLXX. All rights reserved.
//

#import "JLXXRequest.h"
#import "JLXXRequestManager.h"
#import <objc/runtime.h>

NSString *const JLXXRequestValidationErrorDomain = @"com.deerlive.request.validation";

@implementation JLXXRequest


-(void)cheeckRequestParams{
	
	unsigned int count = 0;
	Ivar *ivarList = class_copyIvarList(self.class, &count);
	for (int i = 0 ; i < count; i++) {
		// 获取成员属性
		Ivar ivar = ivarList[i];
		
		// 成员属性类型
		NSString *propertyType = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivar)];
		//是否是字符串
		BOOL isString  = [propertyType containsString:@"NSString"];
		if (!isString) {
			continue;
		}
		//是否为nil
		id ivarValue = object_getIvar(self, ivar);
		if (!ivarValue) {
			object_setIvar(self, ivar, @"");
		}
	}
}

-(instancetype)init{
	if (self = [super init]) {
		self.requestMethod = JLXXRequestMethodPOST;
	}
	return self;
}

-(instancetype)initWithRequestUrl:(NSString *)requestUrl{
	if (self = [super init]) {
		self.requestUrl = requestUrl;
		self.requestMethod = JLXXRequestMethodPOST;
	}
	return self;
}

-(instancetype)initWithRequestParam:(id)requestParam{
	if (self = [super init]) {
		self.requestParam = requestParam;
		self.requestMethod = JLXXRequestMethodPOST;
	}
	return self;
}

-(instancetype)initWithRequestUrl:(NSString *)requestUrl withRequestParam:(nullable id)requestParam{
	if (self = [super init]) {
		self.requestUrl = requestUrl;
		self.requestParam = requestParam;
		self.requestMethod = JLXXRequestMethodPOST;
	}
	return self;
}


#pragma mark - Request Configuration

- (JLXXRequestSerializerType)requestSerializerType {
	return JLXXRequestSerializerTypeHTTP;
}

-(NSArray<NSString *> *)ignoreParams{
	return nil;
}

- (NSArray *)requestAuthorizationHeaderFieldArray {
	return nil;
}

- (NSURLRequest *)currentRequest {
	return self.requestTask.currentRequest;
}

- (NSURLRequest *)originalRequest {
	return self.requestTask.originalRequest;
}

#pragma mark - Response Information

- (JLXXResponseSerializerType)responseSerializerType {
	return JLXXResponseSerializerTypeJSON;
}

-(NSSet<NSString *> *)acceptableContentTypes{
	return [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html" ,@"text/plain",@"audio/mpeg",nil];
}

- (NSHTTPURLResponse *)response {
	return (NSHTTPURLResponse *)self.requestTask.response;
}

- (NSString *)responseStatusCode{
	id statusCode = self.responseObject[self.responseStatusCodeKey];
	statusCode = [NSString stringWithFormat:@"%@",statusCode];
	return statusCode;
}

- (void)cancelRequest{
	[self.requestTask cancel];
}

- (BOOL)isCancelled {
	if (!self.requestTask) {
		return NO;
	}
	return self.requestTask.error.code == NSURLErrorCancelled;
}

- (BOOL)isExecuting {
	if (!self.requestTask) {
		return NO;
	}
	return self.requestTask.state == NSURLSessionTaskStateRunning;
}

- (BOOL)isCallBackWhenCancel{
	return NO;
}

- (BOOL)sendNotifcationWhenUnauthorized {
	return YES;
}

- (BOOL)statusCodeValidator {
	NSString *statusCode = [self responseStatusCode];
	NSArray *successStatusCode = [self successStatusCode];
	
	BOOL status = NO;
	for (NSString *code in successStatusCode) {
		if ([statusCode isEqualToString:code]) { status = YES; break; }
	}
	
	return status;
}

-(NSDictionary *)responseHeaders{
	return self.response.allHeaderFields;
}

-(BOOL)jsonValidator{
	return YES;
}

#pragma mark - Request Action

- (void)start {
	[[JLXXRequestManager sharedInstance] addRequest:self];
}
- (void)startWithCompletionBlockWithSuccess:(JLXXRequestCompletionBlock)success
									failure:(JLXXRequestCompletionBlock)failure {
	[self setCompletionBlockWithSuccess:success failure:failure];
	[self start];
}

- (void)setCompletionBlockWithSuccess:(JLXXRequestCompletionBlock)success
							  failure:(JLXXRequestCompletionBlock)failure {
	self.successCompletionBlock = success;
	self.failureCompletionBlock = failure;
}

- (void)stop {
	[[JLXXRequestManager sharedInstance] cancelRequest:self];
}

- (void)clearCompletionBlock {
	// nil out to break the retain cycle.
	self.successCompletionBlock = nil;
	self.failureCompletionBlock = nil;
	self.constructingBodyBlock = nil;
	self.resumableDownloadProgressBlock = nil;
	self.uploadProgressBlock = nil;
}

- (NSTimeInterval)requestTimeoutInterval {
	return 20;
}

- (BOOL)allowsCellularAccess {
	return YES;
}

-(void)serializedResponseObjectToModel{
	//子类实现
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p>{ URL: %@ } { method: %@ } { arguments: %@ } {status code = %@} ,{error = %@}", NSStringFromClass([self class]), self, self.currentRequest.URL, self.currentRequest.HTTPMethod, self.requestParam,self.responseStatusCode,self.error.localizedDescription];
}

-(void)dealloc{
#ifdef DEBUG
	NSLog(@"requestName: %@ dealloc",NSStringFromClass([self class]));
#else
#endif
	
}

@end

