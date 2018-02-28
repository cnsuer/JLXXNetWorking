//
//  NSObject+JLXXNetWork.h
//  Pods
//
//  Created by apple on 2017/7/17.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (JLXXNetWork)

+(NSArray *)getSignatureaAndTimeStampWithSecretKey:(NSString *)secretKey;

@end
