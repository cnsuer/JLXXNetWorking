//
//  JLXXRequestManager.m
//  sisitv_ios
//
//  Created by apple on 16/12/5.
//  Copyright © 2016年 JLXX--JLXX. All rights reserved.
//
#import "JLXXRequestManager.h"
#import "JLXXRequestConfig.h"
#import "JLXXRequest.h"
#import "NSObject+JLXXNetWork.h"

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

#import <pthread/pthread.h>

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

#define kJLXXNetworkIncompleteDownloadFolderName @"AFDownloaded"

@interface JLXXRequestManager ()

@property (nonatomic) AFHTTPSessionManager *sessionManager;

@property (nonatomic , strong) NSIndexSet *allStatusCodes;

@property (nonatomic , strong) NSMutableDictionary<NSNumber *, JLXXRequest *> *requestsRecord;

@end

@implementation JLXXRequestManager{
	pthread_mutex_t _lock;
	JLXXRequestConfig *_config;
}

+ (instancetype)sharedInstance
{
	static JLXXRequestManager *instance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
	return instance;
}
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(instancetype)init
{
	self = [super init];
	if (self) {
		
		_config = [JLXXRequestConfig sharedInstance];
		
		self.allStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(100, 500)];
		self.requestsRecord = [[NSMutableDictionary alloc] init];
		pthread_mutex_init(&_lock, NULL);
		
		self.sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:_config.sessionConfiguration];
		self.sessionManager.securityPolicy = _config.securityPolicy;
		self.sessionManager.completionQueue = _config.processingQueue;
	}
	return self;
}

-(void)addRequest:(JLXXRequest *)request{
	NSParameterAssert(request != nil);
	
	NSError * __autoreleasing requestSerializationError = nil;
	
	request.requestTask = [self sessionTaskForRequest:request error:&requestSerializationError];
	
	if (requestSerializationError) {
		[self requestDidFailWithRequest:request error:requestSerializationError];
		return;
	}
	
	NSAssert(request.requestTask != nil, @"requestTask should not be nil");
	
	// Retain request
	[self addRequestToRecord:request];
	
#ifdef DEBUG
	NSLog(@"Add request: %@", NSStringFromClass([request class]));
#else
#endif
	[request.requestTask resume];
}

- (NSURLSessionTask *)sessionTaskForRequest:(JLXXRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
	JLXXRequestMethod method = [request requestMethod];
	NSString *url = [self buildRequestUrl:request];
	
	//检查参数是否有nil,把nil参数改为@""
	[request cheeckRequestParams];
	
	//requestParam.
	id param = request.requestParam;
	//如果param没有值,则创建可变的字典,有值,则mutableCopy
	if (!param){
		param = [NSMutableDictionary dictionary];
	}else{
		param = [param mutableCopy];
	}
	//extra 参数
	[param setValuesForKeysWithDictionary:request.extraParam];
	//添加默认参数
	[param setValuesForKeysWithDictionary:_config.defaultParam];
	//需要忽略的参数
	NSArray *ignoreParams = [request ignoreParams];
	for (NSString *key in ignoreParams) {
		[param removeObjectForKey:key];
	}
	//加密
	if (_config.isSecret) {
		[param setObject:[[NSString getSignatureaAndTimeStampWithSecretKey:_config.secretKey] firstObject] forKey:@"sign"];
		[param setObject:[[NSString getSignatureaAndTimeStampWithSecretKey:_config.secretKey] lastObject] forKey:@"timestamp"];
	}
	
	AFConstructingBlock constructingBlock = [request constructingBodyBlock];
	
	AFHTTPResponseSerializer *responseSerializer = [self responseSerializerForRequest:request];
	
	AFHTTPRequestSerializer *requestSerializer = [self requestSerializerForRequest:request];
	
	switch (method) {
		case JLXXRequestMethodGET:
			if (request.isDownload) {
				return [self downloadTaskWithDownloadPath:request.resumableDownloadPath URLString:url parameters:param progress:request.resumableDownloadProgressBlock error:error];
			} else {
				return [self dataTaskWithHTTPMethod:@"GET" requestSerializer:requestSerializer responseSerializer:responseSerializer URLString:url parameters:param constructingBodyWithBlock:nil progress:nil error:error];
			}
		case JLXXRequestMethodPOST:
			return [self dataTaskWithHTTPMethod:@"POST" requestSerializer:requestSerializer responseSerializer:responseSerializer URLString:url parameters:param constructingBodyWithBlock:constructingBlock progress:request.uploadProgressBlock error:error];
	}
}

- (NSString *)buildRequestUrl:(JLXXRequest *)request {
	NSParameterAssert(request != nil);
	
	NSString *detailUrl = [request requestUrl];
	NSURL *temp = [NSURL URLWithString:detailUrl];
	// If detailUrl is valid URL
	if (temp && temp.host && temp.scheme) {
		return detailUrl;
	}
	NSString *baseUrl = [_config baseURL];
	// URL slash compability
	NSURL *url = [NSURL URLWithString:baseUrl];
	
	if (baseUrl.length > 0 && ![baseUrl hasSuffix:@"/"]) {
		url = [url URLByAppendingPathComponent:@""];
	}
	return [NSURL URLWithString:detailUrl relativeToURL:url].absoluteString;
}

-(AFHTTPResponseSerializer *)responseSerializerForRequest:(JLXXRequest *)request{
	AFHTTPResponseSerializer *responseSerializer = nil;
	if (request.responseSerializerType == JLXXResponseSerializerTypeHTTP) {
		responseSerializer = [AFHTTPResponseSerializer serializer];
	} else if (request.responseSerializerType == JLXXResponseSerializerTypeJSON) {
		responseSerializer = [AFJSONResponseSerializer serializer];
	}else if (request.responseSerializerType == JLXXResponseSerializerTypeXMLParser) {
		responseSerializer = [AFXMLParserResponseSerializer serializer];
	}
	responseSerializer.acceptableContentTypes = [request acceptableContentTypes];
	responseSerializer.acceptableStatusCodes = self.allStatusCodes;
	return responseSerializer;
}

- (AFHTTPRequestSerializer *)requestSerializerForRequest:(JLXXRequest *)request {
	AFHTTPRequestSerializer *requestSerializer = nil;
	if (request.requestSerializerType == JLXXRequestSerializerTypeHTTP) {
		requestSerializer = [AFHTTPRequestSerializer serializer];
	} else if (request.requestSerializerType == JLXXRequestSerializerTypeJSON) {
		requestSerializer = [AFJSONRequestSerializer serializer];
	}
	requestSerializer.timeoutInterval = [request requestTimeoutInterval];
	requestSerializer.allowsCellularAccess = [request allowsCellularAccess];
	
	// If api needs server username and password
	NSArray<NSString *> *authorizationHeaderFieldArray = [request requestAuthorizationHeaderFieldArray];
	if (authorizationHeaderFieldArray != nil) {
		[requestSerializer setAuthorizationHeaderFieldWithUsername:authorizationHeaderFieldArray.firstObject
														  password:authorizationHeaderFieldArray.lastObject];
	}
	
	// If api needs to add custom value to HTTPHeaderField
	NSDictionary<NSString *, NSString *> *headerFieldValueDictionary = [request requestHeaderFieldValueDictionary];
	if (headerFieldValueDictionary != nil) {
		for (NSString *httpHeaderField in headerFieldValueDictionary.allKeys) {
			NSString *value = headerFieldValueDictionary[httpHeaderField];
			[requestSerializer setValue:value forHTTPHeaderField:httpHeaderField];
		}
	}
	return requestSerializer;
}

- (NSURLSessionDownloadTask *)downloadTaskWithDownloadPath:(NSString *)downloadPath
												 URLString:(NSString *)URLString
												parameters:(id)parameters
												  progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
													 error:(NSError * _Nullable __autoreleasing *)error {
	NSParameterAssert(downloadPath);
	// add parameters to URL;
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
	
	NSString *downloadTargetPath;
	BOOL isDirectory;
	if(![[NSFileManager defaultManager] fileExistsAtPath:downloadPath isDirectory:&isDirectory]) {
		isDirectory = NO;
	}
	// If targetPath is a directory, use the file name we got from the urlRequest.
	// Make sure downloadTargetPath is always a file, not directory.
	if (isDirectory) {
		NSString *fileName = [urlRequest.URL lastPathComponent];
		downloadTargetPath = [NSString pathWithComponents:@[downloadPath, fileName]];
	} else {
		downloadTargetPath = downloadPath;
	}
	
	// AFN use `moveItemAtURL` to move downloaded file to target path,
	// this method aborts the move attempt if a file already exist at the path.
	// So we remove the exist file before we start the download task.
	// https://github.com/AFNetworking/AFNetworking/issues/3775
	if ([[NSFileManager defaultManager] fileExistsAtPath:downloadTargetPath]) {
		[[NSFileManager defaultManager] removeItemAtPath:downloadTargetPath error:nil];
	}
	
	__block NSURLSessionDownloadTask *downloadTask = nil;
	
	downloadTask = [self.sessionManager downloadTaskWithRequest:urlRequest progress:^(NSProgress * _Nonnull downloadProgress) {
		dispatch_async(dispatch_get_main_queue(), ^{
			downloadProgressBlock(downloadProgress);
		});
	} destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
		return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
	} completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
		[self handleRequestResult:downloadTask responseObject:filePath error:error];
	}];
	return downloadTask;
}

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
							   requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
							 responseSerializer :(AFHTTPResponseSerializer *)responseSerializer
									   URLString:(NSString *)URLString
									  parameters:(id)parameters
					   constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
										progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgressBlock
										   error:(NSError * _Nullable __autoreleasing *)error {
	
	NSMutableURLRequest *request = nil;
	if (block) {
		request = [requestSerializer multipartFormRequestWithMethod:method URLString:URLString parameters:parameters constructingBodyWithBlock:block error:error];
	} else {
		request = [requestSerializer requestWithMethod:method URLString:URLString parameters:parameters error:error];
	}
	
	self.sessionManager.responseSerializer = responseSerializer;
	
	__block NSURLSessionDataTask *dataTask = nil;
	
	if (block) {
		dataTask = [self.sessionManager uploadTaskWithStreamedRequest:request progress:uploadProgressBlock completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
			[self handleRequestResult:dataTask responseObject:responseObject error:error];
		}];
	}else{
		dataTask = [self.sessionManager dataTaskWithRequest:request
										  completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
											  [self handleRequestResult:dataTask responseObject:responseObject error:error];
										  }];
	}
	
	return dataTask;
}

- (void)handleRequestResult:(NSURLSessionTask *)task responseObject:(id)responseObject error:(NSError *)error {
	Lock();
	JLXXRequest *request = self.requestsRecord[@(task.taskIdentifier)];
	Unlock();
	
	if (!request) {
		return;
	}
	
	NSError * __autoreleasing validationError = nil;
	
	NSError *requestError = nil;
	BOOL succeed = NO;
	
	request.responseObject = responseObject;
	
	if (error) {
		succeed = NO;
		requestError = error;
		request.networkError = YES;
	}else if(![responseObject isKindOfClass:[NSDictionary class]]){
		request.networkError = NO;
		succeed = NO;
		requestError  = [NSError errorWithDomain:JLXXRequestValidationErrorDomain code:JLXXRequestValidationErrorInvalidJSONFormat userInfo:@{NSLocalizedDescriptionKey:@"Invalid JSON format"}];
	}else {
		request.networkError = NO;
		succeed = [self validateResult:request error:&validationError];
		requestError = validationError;
	}
	if (succeed) {
		[self requestDidSucceedWithRequest:request];
	}
	else {
		[self requestDidFailWithRequest:request error:requestError];
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self removeRequestFromRecord:request];
		[request clearCompletionBlock];
	});
}

- (BOOL)validateResult:(JLXXRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
	//responseStatusCodeKey没有特殊指定
	NSUInteger responseStatusCodeKeyLengh = [request.responseStatusCodeKey length];
	if (responseStatusCodeKeyLengh == 0) {
		request.responseStatusCodeKey = [JLXXRequestConfig sharedInstance].responseStatusCodeKey;
	}
	//successStatusCode没有特殊指定
	NSArray *successStatusCode = request.successStatusCode;
	if (successStatusCode.count == 0) {
		request.successStatusCode = [JLXXRequestConfig sharedInstance].successStatusCode;
	}
	//responseDescriptionKey没有特殊指定
	NSUInteger responseDescriptionKeyLengh = [request.responseDescriptionKey length];
	if (responseDescriptionKeyLengh == 0) {
		request.responseDescriptionKey = [JLXXRequestConfig sharedInstance].responseStatusCodeKey;
	}
	
	BOOL result = [request statusCodeValidator];
	if (!result) {
		if (error) {
			NSString * des = request.responseDescriptionKey;
			NSString *localizedErrorString = request.responseObject[des];
			if (localizedErrorString) {
				*error = [NSError errorWithDomain:JLXXRequestValidationErrorDomain code:JLXXRequestValidationErrorInvalidStatusCode userInfo:@{NSLocalizedDescriptionKey:localizedErrorString}];
			}
		}
		return result;
	}
	if ([request jsonValidator]) {
		return YES;
	}else{
		*error = [NSError errorWithDomain:JLXXRequestValidationErrorDomain code:JLXXRequestValidationErrorInvalidJSONFormat userInfo:@{NSLocalizedDescriptionKey:@"Invalid JSON format"}];
		return NO;
	}
}

- (void)requestDidSucceedWithRequest:(JLXXRequest *)request {
	
	dispatch_queue_t completionQueue;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
	completionQueue = request.completionQueue ?: dispatch_get_main_queue();
#pragma clang diagnostic pop
	dispatch_async(completionQueue, ^{
		if (request.delegate != nil) {
			[request.delegate requestFinished:request];
		}
		if (request.successCompletionBlock) {
			request.successCompletionBlock(request);
		}
	});
#ifdef DEBUG
	NSLog(@"Succeed Finished Request: %@",request);
#else
#endif
}

- (void)requestDidFailWithRequest:(JLXXRequest *)request error:(NSError *)error {
	request.error = error;
	dispatch_queue_t completionQueue;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
	completionQueue = request.completionQueue ?: dispatch_get_main_queue();
#pragma clang diagnostic pop
	dispatch_async(completionQueue, ^{
		if (request.delegate != nil) {
			[request.delegate requestFailed:request];
		}
		if (request.failureCompletionBlock) {
			request.failureCompletionBlock(request);
		}
	});
#ifdef DEBUG
	NSLog(@"request failed: %@",request);
#else
#endif
}

- (void)addRequestToRecord:(JLXXRequest *)request {
	Lock();
	self.requestsRecord[@(request.requestTask.taskIdentifier)] = request;
	Unlock();
}

- (void)removeRequestFromRecord:(JLXXRequest *)request {
	Lock();
	[_requestsRecord removeObjectForKey:@(request.requestTask.taskIdentifier)];
	Unlock();
	
#ifdef DEBUG
	NSLog(@"remove request:%@ ,Request queue size = %zd",NSStringFromClass([request class]), [_requestsRecord count]);
#else
#endif
}

#pragma mark - Resumable Download

- (NSString *)incompleteDownloadTempCacheFolder {
	NSFileManager *fileManager = [NSFileManager new];
	static NSString *cacheFolder;
	
	if (!cacheFolder) {
		NSString *cacheDir = NSTemporaryDirectory();
		cacheFolder = [cacheDir stringByAppendingPathComponent:kJLXXNetworkIncompleteDownloadFolderName];
	}
	
	NSError *error = nil;
	if(![fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
		cacheFolder = nil;
#ifdef DEBUG
		NSLog(@"Failed to create cache directory at %@", cacheFolder);
#else
#endif
	}
	return cacheFolder;
}

- (NSURL *)incompleteDownloadTempPathForDownloadPath:(NSString *)downloadPath {
	NSString *tempPath = nil;
	tempPath = [[self incompleteDownloadTempCacheFolder] stringByAppendingPathComponent:downloadPath];
	return [NSURL fileURLWithPath:tempPath];
}

#pragma mark - Cancel Request

- (void)cancelRequest:(JLXXRequest *)request {
	NSParameterAssert(request != nil);
	
	[request.requestTask cancel];
	[self removeRequestFromRecord:request];
	[request clearCompletionBlock];
}

- (void)cancelAllRequests {
	Lock();
	NSArray *allKeys = [_requestsRecord allKeys];
	Unlock();
	if (allKeys && allKeys.count > 0) {
		NSArray *copiedKeys = [allKeys copy];
		for (NSNumber *key in copiedKeys) {
			Lock();
			JLXXRequest *request = _requestsRecord[key];
			Unlock();
			// We are using non-recursive lock.
			// Do not lock `stop`, otherwise deadlock may occur.
			[request stop];
		}
	}
}

@end

