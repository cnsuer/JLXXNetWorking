# JLXXNetWorking

[![CI Status](http://img.shields.io/travis/cnsuer/JLXXNetWorking.svg?style=flat)](https://travis-ci.org/cnsuer/JLXXNetWorking)
[![Version](https://img.shields.io/cocoapods/v/JLXXNetWorking.svg?style=flat)](http://cocoapods.org/pods/JLXXNetWorking)
[![License](https://img.shields.io/cocoapods/l/JLXXNetWorking.svg?style=flat)](http://cocoapods.org/pods/JLXXNetWorking)
[![Platform](https://img.shields.io/cocoapods/p/JLXXNetWorking.svg?style=flat)](http://cocoapods.org/pods/JLXXNetWorking)

## Example

网络请求类,改编自[YTKNetWork][YTKNetWork]

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

JLXXNetWorking is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'JLXXNetWorking'
```

## 使用教程参考YTKNetWork

* [基础教程][BasicGuide_cn]
* [高级教程][ProGuide_cn]

## 新加项
###### JLXXRequestConfig && JLXXRequest新加项
* responseStatusCodeKey
* successStatusCode
* responseDescriptionKey

通常服务器返回的json数据中,本次请求的状态码关键字:code,值为200,代表成功,当然了,一个提示语:message,是少不了的,
当请求成功,即code的值为200的话,request的success的回调将被调用,否则faile的回调被调用,此时request.error.descr为message的值:"操作成功"
```objectivec
{
"code": 200,
"data": {
"version": "1.0.1"
},
"message": "操作成功"
}
```
但是有时候,服务器返回的json数据中,有自己的规则,状态码关键字:res_code,值为P001,代表成功,提示语:res_msg

```objectivec
{
"res_code": "P001",
"data": {
"version": "1.0.1"
},
"res_msg": "操作成功"
}
```
此时就可以在JLXXRequestConfig,做统一的配置:

```objectivec
[JLXXRequestConfig sharedInstance].responseStatusCodeKey = @"res_code";
[JLXXRequestConfig sharedInstance].responseDescriptionKey = @"res_msg";
[JLXXRequestConfig sharedInstance].successStatusCode = @[@"P001",@"200"];
```
也可以在每个具体的JLXXRequest子类中,给出相对应的属性

```objectivec
- (NSArray *)successStatusCode{
	return @[@"P001"]
}
```
###### JLXXBatchRequest新加项

```objectivec

@property (nonatomic , assign) BOOL isSometime;

 - (instancetype)initWithAlwaysRequests:(NSArray<JLXXRequest *> *)alwaysRequests sometimeRequests:(NSArray<JLXXRequest *> *)alwaysRequests;

}
```
这里常见于一个页面有多个网络请求,下拉刷新的时候全部请求,上拉加载更多的时候,只加载某一个或几个请求,sometimesRequests里的request,在上拉加载时,不会请求
```objectivec
{

	JLXXHomeBannerRequest *bannerRequest = [[JLXXHomeBannerRequest alloc] init];
	JLXXHomeTermListTequest *termList = [[JLXXHomeTermListTequest alloc] init];
	JLXXHomeGetLiveRequest *getLive = [[JLXXHomeGetLiveRequest alloc] init];

	JLXXBatchRequest *batchRequest = [[JLXXBatchRequest alloc] initWithAlwaysRequests:@[getLive] refreshRequests:@[bannerRequest,termList]];
	batchRequest.isRefresh = self.isRefresh;
	
	[batchRequest startWithCompletionBlockWithSuccess:^(JLXXBatchRequest * _Nonnull batchRequest) {

		NSArray *bannerArray = [NSArray array];
		if ([batchRequest requestInSuccessRequestArray:bannerRequest]) {
			bannerArray = [JLXXHomeBannerModel mj_objectArrayWithKeyValuesArray:banner.responseObject[@"data"]];
			[self addData:@[bannerArray] inSection:0];
		}else{//bannerArray没有数据,清空数据,因为是下拉刷新,如果没有数据,需要清空
		[self addData:@[bannerArray] inSection:0];
	}

	NSArray *termListArray = [NSArray array];
	if ([batchRequest requestInSuccessRequestArray:termList]) {
		termListArray = [JLXXHomeTermListModel mj_objectArrayWithKeyValuesArray:termList.responseObject[@"data"]];
		[self addData:@[termListArray] inSection:1];
	}else{//termListArray没有数据,清空数据,因为是下拉刷新,如果没有数据,需要清空
		[self addData:@[termListArray] inSection:1];
	}

	NSArray *roomList = [NSArray array];
	if ([batchRequest requestInSuccessRequestArray:getLive]) {
		roomList = [JLXXHomeLiveModel mj_objectArrayWithKeyValuesArray:getLive.responseObject[@"info"]];
	}else if(self.isRefresh){
		[AlertTool showErrorInView:self.view withTitle:getLive.error.localizedDescription];
	}
	[self addData:roomList inSection:2];

	} failure:^(JLXXBatchRequest * _Nonnull batchRequest) {
		[super requestDidFaile];
	}];
}
```

## Author

cnsuer, 842393459@qq.com

## License

JLXXNetWorking is available under the MIT license. See the LICENSE file for more info.


<!-- external links -->
[YTKNetWork]:https://github.com/yuantiku/YTKNetwork
[BasicGuide_cn]:https://github.com/yuantiku/YTKNetwork/blob/master/Docs/BasicGuide_cn.md
[ProGuide_cn]:https://github.com/yuantiku/YTKNetwork/blob/master/Docs/ProGuide_cn.md
