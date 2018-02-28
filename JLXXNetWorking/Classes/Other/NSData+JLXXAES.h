//
//  NSData+JLXXAES.h
//  Pods
//
//  Created by apple on 2017/7/18.
//
//

#import <Foundation/Foundation.h>

@interface NSData (JLXXAES)

- (NSData *) decryptedDataWithKey:(NSString *)key;


@end
