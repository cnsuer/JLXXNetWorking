//
//  AFJSONResponseSerializer+AES.m
//  Pods
//
//  Created by apple on 2017/7/18.
//
//

#import "AFJSONResponseSerializer+AES.h"
#import <objc/runtime.h>
#import "NSData+JLXXAES.h"
#import "JLXXRequestConfig.h"

@implementation AFJSONResponseSerializer (AES)

+(void)load{
    [super load];
    // 通过class_getInstanceMethod()函数从当前对象中的method list获取method结构体，如果是类方法就使用class_getClassMethod()函数获取。
    Method fromMethod = class_getInstanceMethod([self class], @selector(responseObjectForResponse:data:error:));
    Method toMethod = class_getInstanceMethod([self class], @selector(jlxx_aesResponseObjectForResponse:data:error:));
 
    method_exchangeImplementations(fromMethod, toMethod);

}

- (id)jlxx_aesResponseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error{

	if ([JLXXRequestConfig sharedInstance].isSecret) {
		NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:dataStr options:0];
		//解密：
		NSData *encrypted = [decodedData decryptedDataWithKey:[JLXXRequestConfig sharedInstance].secretKey];
		return [self jlxx_aesResponseObjectForResponse:response data:encrypted error:error];
	}else{
		return [self jlxx_aesResponseObjectForResponse:response data:data error:error];
	}

}


@end
