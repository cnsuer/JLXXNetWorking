//
//  JLXXRequestConfig.m
//  Pods
//
//  Created by apple on 17/5/12.
//
//

#import "JLXXRequestConfig.h"

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

NSString * const JLXXNetworkingReachabilityDidChangeNotification = @"com.deerlive.networking.reachability.change";
NSString * const JLXXNetworkingReachabilityNotificationStatusItem = @"JLXXNetworkingReachabilityNotificationStatusItem";

@implementation JLXXRequestConfig{
	NSMutableDictionary *_defaultParam;
	dispatch_queue_t _processingQueue;
}

+ (instancetype)sharedInstance{
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
		_baseURL = @"http://kuailai.deerlive.com";
		_securityPolicy = [AFSecurityPolicy defaultPolicy];
		_networkStatus = JLXXNetworkReachabilityStatusUnknown;
		_processingQueue = dispatch_queue_create("com.deerlive.networkRequestManager.JLXXprocess", DISPATCH_QUEUE_CONCURRENT);
		_defaultParam = [self params];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
		[[AFNetworkReachabilityManager sharedManager] startMonitoring];
	}
	return self;
}

- (void)reachabilityChanged:(NSNotification *)notification
{
	JLXXNetworkReachabilityStatus status = [notification.userInfo[AFNetworkingReachabilityNotificationStatusItem] integerValue];
	self.networkStatus = status;
	NSDictionary *userInfo = @{JLXXNetworkingReachabilityNotificationStatusItem:@(status)};
	[[NSNotificationCenter defaultCenter] postNotificationName:JLXXNetworkingReachabilityDidChangeNotification object:nil userInfo:userInfo];
}

-(NSDictionary *)defaultParam{
	return [_defaultParam copy];
}

-(void)appendDefaultParam:(NSDictionary *)param{
	[_defaultParam setValuesForKeysWithDictionary:param];
}
-(void)removeParamFor:(NSString *)key{
	[_defaultParam removeObjectForKey:key];
}
-(NSMutableDictionary *)params{
	NSMutableDictionary * defaultParam = [NSMutableDictionary dictionary];
	[defaultParam setObject:@"ios" forKey:@"os"];
	[defaultParam setObject:[[UIDevice currentDevice] systemVersion] forKey:@"os_ver"];
	[defaultParam setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] forKey:@"soft_ver"];
	return defaultParam;
}

@end

