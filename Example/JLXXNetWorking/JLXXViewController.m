//
//  JLXXViewController.m
//  JLXXNetWorking
//
//  Created by cnsuer on 02/28/2018.
//  Copyright (c) 2018 cnsuer. All rights reserved.
//

#import "JLXXViewController.h"
#import <JLXXNetWorking/JLXXNetWorking.h>


@interface JLXXViewController ()

@property (nonatomic , assign) BOOL isRefresh;

@end

@implementation JLXXViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
	
	[self request];
	
}

- (void)request{
	[JLXXRequestConfig sharedInstance].responseStatusCodeKey = @"res_code";
	[JLXXRequestConfig sharedInstance].responseDescriptionKey = @"res_msg";
	[JLXXRequestConfig sharedInstance].successStatusCode = @[@"P001",@"200"];
	JLXXRequest *re1 = [[JLXXRequest alloc] initWithRequestUrl:@"http://api.wawa.kinlink.cn/V2/shangjia"];
	[re1 startWithCompletionBlockWithSuccess:^(__kindof JLXXRequest * _Nonnull request) {
		NSLog(@"success");
	} failure:^(__kindof JLXXRequest * _Nonnull request) {
		NSLog(@"faile");
	}];
}

- (void)configCodeAndDescKey{
	[JLXXRequestConfig sharedInstance].responseStatusCodeKey = @"code";
	[JLXXRequestConfig sharedInstance].responseDescriptionKey = @"desc";

	JLXXRequest *re1 = [[JLXXRequest alloc] initWithRequestUrl:@"/Api/SiSi/is_shangjia"];
	[re1 startWithCompletionBlockWithSuccess:^(__kindof JLXXRequest * _Nonnull request) {
		NSLog(@"success");
	} failure:^(__kindof JLXXRequest * _Nonnull request) {
		NSLog(@"faile-----%@",request.error.localizedDescription);
	}];
}

- (void)batch{
	self.isRefresh = !self.isRefresh;
	NSLog(@"self.isRefresh-----%d",self.isRefresh);


	[JLXXRequestConfig sharedInstance].responseStatusCodeKey = @"code";
	[JLXXRequestConfig sharedInstance].responseDescriptionKey = @"desc";

	
	JLXXRequest *re1 = [[JLXXRequest alloc] initWithRequestUrl:@"/Api/SiSi/is_shangjia"];
	JLXXRequest *re2 = [[JLXXRequest alloc] initWithRequestUrl:@"/api/22"];
	JLXXRequest *re3 = [[JLXXRequest alloc] initWithRequestUrl:@"/api/33"];
	JLXXRequest *re4 = [[JLXXRequest alloc] initWithRequestUrl:@"/api/44"];
	
	JLXXBatchRequest *batch = [[JLXXBatchRequest alloc] initWithAlwaysRequests:@[re4,re3,re2] refreshRequests:@[re1]];
	batch.isRefresh = self.isRefresh;
	
	[batch startWithCompletionBlockWithSuccess:^(JLXXBatchRequest * _Nonnull batchRequest) {
		NSLog(@"%@",batchRequest.successRequests);
		NSLog(@"%@",batchRequest.failedRequests);
	} failure:^(JLXXBatchRequest * _Nonnull batchRequest) {
		NSLog(@"all Request 失败");
		NSLog(@"%@",[NSThread currentThread]);
	}];
}



@end
