//
//  ZWTHTTPManager.m
//  ZWTSessionDemo
//
//  Created by joywii on 15/2/5.
//  Copyright (c) 2015年 joywii. All rights reserved.
//

#import "ZWTHTTPRequest.h"
#import "ZWTHTTPUtil.h"

@interface ZWTHTTPRequest ()

@property (readwrite, nonatomic, strong) NSURL *baseURL;

@end

@implementation ZWTHTTPRequest

+ (instancetype)shareRequest
{
    static ZWTHTTPRequest *shareHTTPRequest;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        shareHTTPRequest = [[ZWTHTTPRequest alloc] initWithBaseURL:nil];
    });
    return shareHTTPRequest;
}
- (instancetype)init
{
    return [self initWithBaseURL:nil];
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
    return [self initWithBaseURL:url sessionConfiguration:nil];
}

- (instancetype)initWithBaseURL:(NSURL *)url
           sessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    self = [super initWithSessionConfiguration:configuration];
    if (!self) {
        return nil;
    }
    _baseURL = url;
    return self;
}

- (NSURLSessionDataTask *)GET:(NSString *)URLString
                   parameters:(id)parameters
                      success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                      failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:@"GET"
                                                        URLString:URLString
                                                       parameters:parameters
                                                         fileData:nil
                                                          success:success
                                                          failure:failure];
    [dataTask resume];
    
    return dataTask;
}
- (NSURLSessionDataTask *)HEAD:(NSString *)URLString
                    parameters:(id)parameters
                       success:(void (^)(NSURLSessionDataTask *task))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:@"HEAD"
                                                        URLString:URLString
                                                       parameters:parameters
                                                         fileData:nil
                                                          success:^(NSURLSessionDataTask *task, __unused id responseObject)
    {
        if (success) {
            success(task);
        }
    } failure:failure];
    
    [dataTask resume];
    
    return dataTask;
}
- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(id)parameters
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:@"POST"
                                                        URLString:URLString
                                                       parameters:parameters
                                                         fileData:nil
                                                          success:success
                                                          failure:failure];
    [dataTask resume];
    
    return dataTask;
}
- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(id)parameters
                      fileData:fileData
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:@"POST"
                                                        URLString:URLString
                                                       parameters:parameters
                                                         fileData:fileData
                                                          success:success
                                                          failure:failure];
    [dataTask resume];
    
    return dataTask;
}
- (NSURLSessionDataTask *)PUT:(NSString *)URLString
                   parameters:(id)parameters
                      success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                      failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:@"PUT"
                                                        URLString:URLString
                                                       parameters:parameters
                                                         fileData:nil
                                                          success:success
                                                          failure:failure];
    
    [dataTask resume];
    
    return dataTask;
}

- (NSURLSessionDataTask *)PATCH:(NSString *)URLString
                     parameters:(id)parameters
                        success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                        failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:@"PATCH"
                                                        URLString:URLString
                                                       parameters:parameters
                                                         fileData:nil
                                                          success:success
                                                          failure:failure];
    
    [dataTask resume];
    
    return dataTask;
}

- (NSURLSessionDataTask *)DELETE:(NSString *)URLString
                      parameters:(id)parameters
                         success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                         failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:@"DELETE"
                                                        URLString:URLString
                                                       parameters:parameters
                                                         fileData:nil
                                                          success:success
                                                          failure:failure];
    
    [dataTask resume];
    
    return dataTask;
}
- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                        fileData:(id)fileData
                                         success:(void (^)(NSURLSessionDataTask *, id))success
                                         failure:(void (^)(NSURLSessionDataTask *, NSError *))failure
{
    NSString *urlString = [[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString];
    NSMutableURLRequest *request = [[ZWTHTTPUtil shareHTTPUtil] requestWithMethod:method URLString:urlString parameters:parameters fileData:fileData];
    
    __block NSURLSessionDataTask *dataTask = nil;
    if (fileData) {
        dataTask = [self uploadTaskWithStreamedRequest:request progress:nil completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
            if (error) {
                if (failure) {
                    failure(dataTask, error);
                }
            } else {
                if (success) {
                    success(dataTask, responseObject);
                }
            }
        }];
    } else {
        dataTask = [self dataTaskWithRequest:request  completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
            if (error) {
                if (failure) {
                    failure(dataTask, error);
                }
            } else {
                if (success) {
                    success(dataTask, responseObject);
                }
            }
        }];
    }
    return dataTask;
}

@end
