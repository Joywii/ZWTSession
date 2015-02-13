//
//  ZWTBackgroundRequest.h
//  ZWTSessionDemo
//
//  Created by joywii on 15/2/9.
//  Copyright (c) 2015年 joywii. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZWTSessionManager.h"

@protocol ZWTBackgroundRequestDelegate <NSObject>

- (void)didFinishEventsForBackgroundURLSession:(NSURLSession *)session;

@end

@interface ZWTBackgroundRequest : ZWTSessionManager

@property (readonly, nonatomic, strong) NSURL *baseURL;

- (instancetype)initWithDelegate:(id<ZWTBackgroundRequestDelegate> )delegate
           sessionConfiguration:(NSURLSessionConfiguration *)configuration;

- (NSURLSessionUploadTask *)uploadBackground:(NSString *)URLString
                                  parameters:(id)parameters
                                    fileData:(id)fileData
                                    progress:(NSProgress * __autoreleasing *)progress
                                     success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                                     failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

- (NSURLSessionDownloadTask *)downloadBackground:(NSString *)URLString
                                      parameters:(id)parameters
                                        progress:(NSProgress * __autoreleasing *)progress
                                     destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                               completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler;

@end
