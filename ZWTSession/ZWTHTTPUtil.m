//
//  ZWTHTTPUtil.m
//  ZWTSessionDemo
//
//  Created by joywii on 15/2/10.
//  Copyright (c) 2015年 joywii. All rights reserved.
//

#import "ZWTHTTPUtil.h"

static NSString * const kAFCharactersToBeEscapedInQueryString = @":/?&=;+!@#$()',*";

static NSString * AFPercentEscapedQueryStringKeyFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
    static NSString * const kAFCharactersToLeaveUnescapedInQueryStringPairKey = @"[].";
    
    return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, (__bridge CFStringRef)kAFCharactersToLeaveUnescapedInQueryStringPairKey, (__bridge CFStringRef)kAFCharactersToBeEscapedInQueryString, CFStringConvertNSStringEncodingToEncoding(encoding));
}

static NSString * AFPercentEscapedQueryStringValueFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
    return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)kAFCharactersToBeEscapedInQueryString, CFStringConvertNSStringEncodingToEncoding(encoding));
}

@implementation ZWTHTTPUtil

+ (instancetype)shareHTTPUtil
{
    static ZWTHTTPUtil *httpUtil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        httpUtil = [[ZWTHTTPUtil alloc] init];
    });
    return httpUtil;
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(NSDictionary *)parameters
                                  fileData:(NSDictionary *)fileData
{
    NSString *urlString = [self generateURL:URLString params:parameters httpMedthod:method];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:method];
    
//    //添加HTTP Head信息
//    if (headerFields)
//    {
//        NSEnumerator *headKeys = [headerFields keyEnumerator];
//        int i;
//        for (i = 0; i < [headerFields count]; i++)
//        {
//            NSString *key = [headKeys nextObject];
//            id value = [headerFields objectForKey:key];
//            if ([value isKindOfClass:[NSString class]])
//            {
//                [request addValue:value forHTTPHeaderField:key];
//            }
//        }
//    }
    //添加HTTP Body信息
    if ([method isEqualToString:@"POST"])
    {
        //创建Body
        NSMutableData *postBody = [NSMutableData data];
        if (fileData)
        {
            //添加Head
            NSString *stringBoundary = @"0xKhTmLbOuNdArY";
            NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",stringBoundary];
            [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
            
            //开始
            [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
            NSString *itemEndBoundary = [NSString stringWithFormat:@"\r\n--%@\r\n",stringBoundary];
            //添加Params
            if (parameters)
            {
                NSEnumerator *keys = [parameters keyEnumerator];
                int i;
                for (i = 0; i < [parameters count]; i++)
                {
                    NSString *key = [keys nextObject];
                    [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",key] dataUsingEncoding:NSUTF8StringEncoding]];
                    [postBody appendData:[[NSString stringWithFormat:@"%@",[parameters objectForKey:key]] dataUsingEncoding:NSUTF8StringEncoding]];
                    if (i != ([parameters count] - 1) || [fileData count] > 0)
                    {
                        [postBody appendData:[itemEndBoundary dataUsingEncoding:NSUTF8StringEncoding]];
                    }
                }
            }
            //添加Files
            if (fileData)
            {
                NSEnumerator *keys = [fileData keyEnumerator];
                int i;
                for (i = 0; i < [fileData count]; i++)
                {
                    NSString *key = [keys nextObject];
                    [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"file.jpg\"\r\n",key] dataUsingEncoding:NSUTF8StringEncoding]];//application/octet-stream
                    [postBody appendData:[[NSString stringWithFormat:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
                    [postBody appendData:(NSData *)[fileData objectForKey:key]];
                    if (i != ([fileData count] - 1))
                    {
                        [postBody appendData:[itemEndBoundary dataUsingEncoding:NSUTF8StringEncoding]];
                    }
                }
            }
            //结束
            [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        }
        else
        {
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            if (parameters)
            {
                NSEnumerator *keys = [parameters keyEnumerator];
                int i;
                NSUInteger count = [parameters count] - 1;
                for (i = 0; i < [parameters count]; i++)
                {
                    NSString *key = [keys nextObject];
                    NSString *bodyString = [NSString stringWithFormat:@"%@=%@%@",key,[parameters objectForKey:key],(i<count ?  @"&" : @"")];
                    [postBody appendData:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
                }
            }
        }
        //添加Body
        [request setHTTPBody:postBody];
    }
    else if([method isEqualToString:@"GET"])
    {
        
    }
    return request;
}
- (NSString *)generateURL:(NSString *)baseURL params:(NSDictionary *)params httpMedthod:(NSString *)medthod
{
    if ([medthod isEqualToString:@"POST"])
    {
        return baseURL;
    }
    NSURL *parsedURL = [NSURL URLWithString:baseURL];
    NSString *queryPrefix = parsedURL.query ? @"&" : @"?";
    NSString *query = [self stringFromDictionary:params];
    return [NSString stringWithFormat:@"%@%@%@", baseURL, queryPrefix, query];
}
- (NSString *)stringFromDictionary:(NSDictionary *)dict
{
    NSMutableArray *pairs = [NSMutableArray array];
    for (id key in [dict keyEnumerator])
    {
        id value = [dict valueForKey:key];
        
        NSString *keyString = AFPercentEscapedQueryStringKeyFromStringWithEncoding([key description],NSUTF8StringEncoding);
        NSString *valueString = AFPercentEscapedQueryStringValueFromStringWithEncoding([value description],NSUTF8StringEncoding);
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", keyString,valueString]];
        
    }
    return [pairs componentsJoinedByString:@"&"];
}
@end
