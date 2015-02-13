//
//  ZWTBackgroundRequest.m
//  ZWTSessionDemo
//
//  Created by joywii on 15/2/9.
//  Copyright (c) 2015年 joywii. All rights reserved.
//

#import "ZWTBackgroundRequest.h"
#import "ZWTHTTPUtil.h"


@interface ZWTBackgroundRequest ()

@property (nonatomic, weak,) id<ZWTBackgroundRequestDelegate> delegate;

@end

@implementation ZWTBackgroundRequest

- (instancetype)initWithDelegate:(id<ZWTBackgroundRequestDelegate> )delegate
           sessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    self = [super initWithSessionConfiguration:configuration];
    if (!self) {
        return nil;
    }
    _delegate = delegate;
    return self;
}

- (NSURLSessionUploadTask *)uploadBackground:(NSString *)URLString
                                  parameters:(id)parameters
                                    fileData:(id)fileData
                                    progress:(NSProgress * __autoreleasing *)progress
                                     success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                                     failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSString *urlString = [[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString];
    NSMutableURLRequest *request = [[ZWTHTTPUtil shareHTTPUtil] requestWithMethod:@"POST" URLString:urlString parameters:parameters fileData:fileData];
    
    __block NSURLSessionUploadTask *uploadTask = nil;
    uploadTask = [self uploadTaskWithStreamedRequest:request progress:progress completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
        if (error) {
            if (failure) {
                failure(uploadTask, error);
            }
        } else {
            if (success) {
                success(uploadTask, responseObject);
            }
        }
    }];
    return uploadTask;
}

- (NSURLSessionDownloadTask *)downloadBackground:(NSString *)URLString
                                      parameters:(id)parameters
                                        progress:(NSProgress * __autoreleasing *)progress
                                     destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                               completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
{
    NSString *urlString = [[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString];
    NSMutableURLRequest *request = [[ZWTHTTPUtil shareHTTPUtil] requestWithMethod:@"GET" URLString:urlString parameters:parameters fileData:nil];
    
    __block NSURLSessionDownloadTask *downloadTask = nil;
    downloadTask = [self downloadTaskWithRequest:request progress:progress destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        return destination(targetPath,response);
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        completionHandler(response,filePath,error);
    }];
    return downloadTask;
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didFinishEventsForBackgroundURLSession:)]) {
        [self.delegate didFinishEventsForBackgroundURLSession:session];
    }
}
@end
