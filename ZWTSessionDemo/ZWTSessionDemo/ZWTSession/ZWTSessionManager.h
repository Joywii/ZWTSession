//
//  ZWTSessionManager.h
//  ZWTSessionDemo
//
//  Created by joywii on 15/2/5.
//  Copyright (c) 2015年 joywii. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface ZWTSessionManager : NSObject

@property (readonly, nonatomic, strong) NSURLSession *session;

@property (readonly, nonatomic, strong) NSOperationQueue *operationQueue;


@property (nonatomic, strong) dispatch_queue_t completionQueue;
@property (nonatomic, strong) dispatch_group_t completionGroup;

@property (nonatomic, assign) BOOL attemptsToRecreateUploadTasksForBackgroundSessions;


- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration;

- (void)invalidateSessionCancelingTasks:(BOOL)cancelPendingTasks;

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler;

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromFile:(NSURL *)fileURL
                                         progress:(NSProgress * __autoreleasing *)progress
                                completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler;

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromData:(NSData *)bodyData
                                         progress:(NSProgress * __autoreleasing *)progress
                                completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler;

- (NSURLSessionUploadTask *)uploadTaskWithStreamedRequest:(NSURLRequest *)request
                                                 progress:(NSProgress * __autoreleasing *)progress
                                        completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler;

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                             progress:(NSProgress * __autoreleasing *)progress
                                          destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                                    completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler;

- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(NSData *)resumeData
                                                progress:(NSProgress * __autoreleasing *)progress
                                             destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                                       completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler;

//用来继承
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session;

@end
