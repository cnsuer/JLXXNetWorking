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

@end

@implementation JLXXViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	JLXXRequest *re1 = [[JLXXRequest alloc] initWithRequestUrl:@"api/11"];
	JLXXRequest *re2 = [[JLXXRequest alloc] initWithRequestUrl:@"api/22"];
	JLXXRequest *re3 = [[JLXXRequest alloc] initWithRequestUrl:@"api/33"];
	JLXXRequest *re4 = [[JLXXRequest alloc] initWithRequestUrl:@"api/44"];

	JLXXBatchRequest *batch = [[JLXXBatchRequest alloc] initWithRequestArray:@[re1,re2,re3,re4]];
	
	[batch startWithCompletionBlockWithSuccess:^(JLXXBatchRequest * _Nonnull batchRequest) {
		NSLog(@"%@",batchRequest.successRequests);
	} failure:^(JLXXBatchRequest * _Nonnull batchRequest) {
		
		if ([batchRequest request:re2 inRequestArray:batchRequest.failedRequests]) {
			NSLog(@"re2.requestUrl  %@",re2.requestUrl);
		}
		
	}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
