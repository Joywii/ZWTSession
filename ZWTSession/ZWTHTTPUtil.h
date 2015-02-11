//
//  ZWTHTTPUtil.h
//  ZWTSessionDemo
//
//  Created by joywii on 15/2/10.
//  Copyright (c) 2015年 joywii. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZWTHTTPUtil : NSObject

+ (instancetype)shareHTTPUtil;

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(NSDictionary *)parameters
                                  fileData:(NSDictionary *)fileData;

@end
