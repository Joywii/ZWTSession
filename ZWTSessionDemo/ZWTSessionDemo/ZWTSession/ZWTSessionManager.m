//
//  ZWTSessionManager.m
//  ZWTSessionDemo
//
//  Created by joywii on 15/2/5.
//  Copyright (c) 2015年 joywii. All rights reserved.
//

#import "ZWTSessionManager.h"
#import "ZWTHTTPUtil.h"

static dispatch_queue_t url_session_manager_creation_queue() {
    static dispatch_queue_t af_url_session_manager_creation_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        af_url_session_manager_creation_queue = dispatch_queue_create("com.alamofire.networking.session.manager.creation", DISPATCH_QUEUE_SERIAL);
    });
    
    return af_url_session_manager_creation_queue;
}

static dispatch_queue_t url_session_manager_processing_queue() {
    static dispatch_queue_t af_url_session_manager_processing_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        af_url_session_manager_processing_queue = dispatch_queue_create("com.alamofire.networking.session.manager.processing", DISPATCH_QUEUE_CONCURRENT);
    });
    
    return af_url_session_manager_processing_queue;
}

static dispatch_group_t url_session_manager_completion_group() {
    static dispatch_group_t af_url_session_manager_completion_group;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        af_url_session_manager_completion_group = dispatch_group_create();
    });
    
    return af_url_session_manager_completion_group;
}

static NSUInteger const AFMaximumNumberOfAttemptsToRecreateBackgroundSessionUploadTask = 3;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

typedef NSURL * (^ZWTSessionDownloadTaskDidFinishDownloadingBlock)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location);
typedef void (^ZWTSessionTaskCompletionHandler)(NSURLResponse *response, id responseObject, NSError *error);

@interface ZWTSessionTaskDelegate : NSObject <NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, weak) ZWTSessionManager *manager;
@property (nonatomic, strong) NSMutableData *mutableData;
@property (nonatomic, strong) NSProgress *progress;
@property (nonatomic, copy) NSURL *downloadFileURL;
@property (nonatomic, copy) ZWTSessionDownloadTaskDidFinishDownloadingBlock downloadTaskDidFinishDownloading;
@property (nonatomic, copy) ZWTSessionTaskCompletionHandler completionHandler;

@end
@implementation ZWTSessionTaskDelegate

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.mutableData = [NSMutableData data];
    
    self.progress = [NSProgress progressWithTotalUnitCount:0];
    
    return self;
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(__unused NSURLSession *)session
              task:(__unused NSURLSessionTask *)task
   didSendBodyData:(__unused int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    self.progress.totalUnitCount = totalBytesExpectedToSend;
    self.progress.completedUnitCount = totalBytesSent;
}

- (void)URLSession:(__unused NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
    __strong ZWTSessionManager *manager = self.manager;
    
    __block id responseObject = nil;
    
    if (error) {
        dispatch_group_async(manager.completionGroup ?: url_session_manager_completion_group(), manager.completionQueue ?: dispatch_get_main_queue(), ^{
            if (self.completionHandler) {
                self.completionHandler(task.response, responseObject, error);
            }
        });
    } else {
        dispatch_async(url_session_manager_processing_queue(), ^{
            NSError *serializationError = nil;
            responseObject = [self responseObjectFordata:[NSData dataWithData:self.mutableData] error:&serializationError];
            
            if (self.downloadFileURL) {
                responseObject = self.downloadFileURL;
            }
            
            dispatch_group_async(manager.completionGroup ?: url_session_manager_completion_group(), manager.completionQueue ?: dispatch_get_main_queue(), ^{
                if (self.completionHandler) {
                    self.completionHandler(task.response, responseObject, serializationError);
                }
            });
        });
    }
#pragma clang diagnostic pop
}
- (id)responseObjectFordata:(NSData *)data
                      error:(NSError *__autoreleasing *)error
{
    id responseObject = nil;
    NSError *serializationError = nil;
    @autoreleasepool {
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (responseString && ![responseString isEqualToString:@" "]) {
            // Workaround for a bug in NSJSONSerialization when Unicode character escape codes are used instead of the actual character
            // See http://stackoverflow.com/a/12843465/157142
            data = [responseString dataUsingEncoding:NSUTF8StringEncoding];
            
            if (data) {
                if ([data length] > 0) {
                    responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&serializationError];
                } else {
                    return nil;
                }
            } else {
                *error = [NSError errorWithDomain:@"response data null" code:NSURLErrorCannotDecodeContentData userInfo:nil];
            }
        }
    }
    *error = serializationError;
    return responseObject;
}
#pragma mark - NSURLSessionDataTaskDelegate

- (void)URLSession:(__unused NSURLSession *)session
          dataTask:(__unused NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    [self.mutableData appendData:data];
}

#pragma mark - NSURLSessionDownloadTaskDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    NSError *fileManagerError = nil;
    self.downloadFileURL = nil;
    
    if (self.downloadTaskDidFinishDownloading) {
        self.downloadFileURL = self.downloadTaskDidFinishDownloading(session, downloadTask, location);
        if (self.downloadFileURL) {
            [[NSFileManager defaultManager] moveItemAtURL:location toURL:self.downloadFileURL error:&fileManagerError];
            
            if (fileManagerError) {
            }
        }
    }
}

- (void)URLSession:(__unused NSURLSession *)session
      downloadTask:(__unused NSURLSessionDownloadTask *)downloadTask
      didWriteData:(__unused int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    self.progress.totalUnitCount = totalBytesExpectedToWrite;
    self.progress.completedUnitCount = totalBytesWritten;
}

- (void)URLSession:(__unused NSURLSession *)session
      downloadTask:(__unused NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {
    self.progress.totalUnitCount = expectedTotalBytes;
    self.progress.completedUnitCount = fileOffset;
}

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


@interface ZWTSessionManager () <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>

@property (readwrite, nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;
@property (readwrite, nonatomic, strong) NSOperationQueue *operationQueue;
@property (readwrite, nonatomic, strong) NSURLSession *session;
@property (readwrite, nonatomic, strong) NSMutableDictionary *mutableTaskDelegatesKeyedByTaskIdentifier;
@property (readwrite, nonatomic, strong) NSLock *lock;

@end

@implementation ZWTSessionManager

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    if (!configuration) {
        configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    }
    
    self.sessionConfiguration = configuration;
    
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = 1;
    
    self.session = [NSURLSession sessionWithConfiguration:self.sessionConfiguration delegate:self delegateQueue:self.operationQueue];

    self.mutableTaskDelegatesKeyedByTaskIdentifier = [[NSMutableDictionary alloc] init];
    self.lock = [[NSLock alloc] init];
    self.lock.name = @"com.kingzwt.session.manager.lock";
    
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        for (NSURLSessionDataTask *task in dataTasks) {
            [self addDelegateForDataTask:task completionHandler:nil];
        }
        
        for (NSURLSessionUploadTask *uploadTask in uploadTasks) {
            [self addDelegateForUploadTask:uploadTask progress:nil completionHandler:nil];
        }
        
        for (NSURLSessionDownloadTask *downloadTask in downloadTasks) {
            [self addDelegateForDownloadTask:downloadTask progress:nil destination:nil completionHandler:nil];
        }
    }];
    return self;
}
#pragma mark -

- (ZWTSessionTaskDelegate *)delegateForTask:(NSURLSessionTask *)task {
    NSParameterAssert(task);
    
    ZWTSessionTaskDelegate *delegate = nil;
    [self.lock lock];
    delegate = self.mutableTaskDelegatesKeyedByTaskIdentifier[@(task.taskIdentifier)];
    [self.lock unlock];
    
    return delegate;
}

- (void)setDelegate:(ZWTSessionTaskDelegate *)delegate
            forTask:(NSURLSessionTask *)task
{
    NSParameterAssert(task);
    NSParameterAssert(delegate);
    [self.lock lock];
    self.mutableTaskDelegatesKeyedByTaskIdentifier[@(task.taskIdentifier)] = delegate;
    [self.lock unlock];
}

- (void)addDelegateForDataTask:(NSURLSessionDataTask *)dataTask
             completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler
{
    ZWTSessionTaskDelegate *delegate = [[ZWTSessionTaskDelegate alloc] init];
    delegate.manager = self;
    delegate.completionHandler = completionHandler;
    
    [self setDelegate:delegate forTask:dataTask];
}

- (void)addDelegateForUploadTask:(NSURLSessionUploadTask *)uploadTask
                        progress:(NSProgress * __autoreleasing *)progress
               completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler
{
    ZWTSessionTaskDelegate *delegate = [[ZWTSessionTaskDelegate alloc] init];
    delegate.manager = self;
    delegate.completionHandler = completionHandler;
    
    int64_t totalUnitCount = uploadTask.countOfBytesExpectedToSend;
    if(totalUnitCount == NSURLSessionTransferSizeUnknown) {
        NSString *contentLength = [uploadTask.originalRequest valueForHTTPHeaderField:@"Content-Length"];
        if(contentLength) {
            totalUnitCount = (int64_t) [contentLength longLongValue];
        }
    }
    
    delegate.progress = [NSProgress progressWithTotalUnitCount:totalUnitCount];
    delegate.progress.pausingHandler = ^{
        [uploadTask suspend];
    };
    delegate.progress.cancellationHandler = ^{
        [uploadTask cancel];
    };
    
    if (progress) {
        *progress = delegate.progress;
    }
    
    [self setDelegate:delegate forTask:uploadTask];
}

- (void)addDelegateForDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                          progress:(NSProgress * __autoreleasing *)progress
                       destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                 completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
{
    ZWTSessionTaskDelegate *delegate = [[ZWTSessionTaskDelegate alloc] init];
    delegate.manager = self;
    delegate.completionHandler = completionHandler;
    
    if (destination) {
        delegate.downloadTaskDidFinishDownloading = ^NSURL * (NSURLSession * __unused session, NSURLSessionDownloadTask *task, NSURL *location) {
            return destination(location, task.response);
        };
    }
    
    if (progress) {
        *progress = delegate.progress;
    }
    
    [self setDelegate:delegate forTask:downloadTask];
}

- (void)removeDelegateForTask:(NSURLSessionTask *)task {
    NSParameterAssert(task);
    [self.lock lock];
    [self.mutableTaskDelegatesKeyedByTaskIdentifier removeObjectForKey:@(task.taskIdentifier)];
    [self.lock unlock];
}

- (void)removeAllDelegates {
    [self.lock lock];
    [self.mutableTaskDelegatesKeyedByTaskIdentifier removeAllObjects];
    [self.lock unlock];
}

- (void)invalidateSessionCancelingTasks:(BOOL)cancelPendingTasks {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (cancelPendingTasks) {
            [self.session invalidateAndCancel];
        } else {
            [self.session finishTasksAndInvalidate];
        }
    });
}
#pragma mark - NSURLSessionDataTask

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler
{
    __block NSURLSessionDataTask *dataTask = nil;
    dispatch_sync(url_session_manager_creation_queue(), ^{
        dataTask = [self.session dataTaskWithRequest:request];
    });
    
    [self addDelegateForDataTask:dataTask completionHandler:completionHandler];
    
    return dataTask;
}
#pragma mark - NSURLSessionUploadTask

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromFile:(NSURL *)fileURL
                                         progress:(NSProgress * __autoreleasing *)progress
                                completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler
{
    __block NSURLSessionUploadTask *uploadTask = nil;
    dispatch_sync(url_session_manager_creation_queue(), ^{
        uploadTask = [self.session uploadTaskWithRequest:request fromFile:fileURL];
    });
    
    if (!uploadTask && self.attemptsToRecreateUploadTasksForBackgroundSessions && self.session.configuration.identifier) {
        for (NSUInteger attempts = 0; !uploadTask && attempts < AFMaximumNumberOfAttemptsToRecreateBackgroundSessionUploadTask; attempts++) {
            uploadTask = [self.session uploadTaskWithRequest:request fromFile:fileURL];
        }
    }
    
    [self addDelegateForUploadTask:uploadTask progress:progress completionHandler:completionHandler];
    
    return uploadTask;
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromData:(NSData *)bodyData
                                         progress:(NSProgress * __autoreleasing *)progress
                                completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler
{
    __block NSURLSessionUploadTask *uploadTask = nil;
    dispatch_sync(url_session_manager_creation_queue(), ^{
        uploadTask = [self.session uploadTaskWithRequest:request fromData:bodyData];
    });
    
    [self addDelegateForUploadTask:uploadTask progress:progress completionHandler:completionHandler];
    
    return uploadTask;
}

- (NSURLSessionUploadTask *)uploadTaskWithStreamedRequest:(NSURLRequest *)request
                                                 progress:(NSProgress * __autoreleasing *)progress
                                        completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler
{
    __block NSURLSessionUploadTask *uploadTask = nil;
    dispatch_sync(url_session_manager_creation_queue(), ^{
        uploadTask = [self.session uploadTaskWithStreamedRequest:request];
    });
    
    [self addDelegateForUploadTask:uploadTask progress:progress completionHandler:completionHandler];
    
    return uploadTask;
}
#pragma mark - NSURLSessionDownloadTask

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                             progress:(NSProgress * __autoreleasing *)progress
                                          destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                                    completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
{
    __block NSURLSessionDownloadTask *downloadTask = nil;
    dispatch_sync(url_session_manager_creation_queue(), ^{
        downloadTask = [self.session downloadTaskWithRequest:request];
    });
    
    [self addDelegateForDownloadTask:downloadTask progress:progress destination:destination completionHandler:completionHandler];
    
    return downloadTask;
}

- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(NSData *)resumeData
                                                progress:(NSProgress * __autoreleasing *)progress
                                             destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                                       completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
{
    __block NSURLSessionDownloadTask *downloadTask = nil;
    dispatch_sync(url_session_manager_creation_queue(), ^{
        downloadTask = [self.session downloadTaskWithResumeData:resumeData];
    });
    
    [self addDelegateForDownloadTask:downloadTask progress:progress destination:destination completionHandler:completionHandler];
    
    return downloadTask;
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session
didBecomeInvalidWithError:(NSError *)error
{
    [self removeAllDelegates];
}

- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    //TODO:
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
    } else {
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}
#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler
{
    NSURLRequest *redirectRequest = request;
    
    if (completionHandler) {
        completionHandler(redirectRequest);
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
    } else {
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
 needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler
{
    NSInputStream *inputStream = nil;
    
    if (task.originalRequest.HTTPBodyStream && [task.originalRequest.HTTPBodyStream conformsToProtocol:@protocol(NSCopying)]) {
        inputStream = [task.originalRequest.HTTPBodyStream copy];
    }
    
    if (completionHandler) {
        completionHandler(inputStream);
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    int64_t totalUnitCount = totalBytesExpectedToSend;
    if(totalUnitCount == NSURLSessionTransferSizeUnknown) {
        NSString *contentLength = [task.originalRequest valueForHTTPHeaderField:@"Content-Length"];
        if(contentLength) {
            totalUnitCount = (int64_t) [contentLength longLongValue];
        }
    }
    
    ZWTSessionTaskDelegate *delegate = [self delegateForTask:task];
    [delegate URLSession:session task:task didSendBodyData:bytesSent totalBytesSent:totalBytesSent totalBytesExpectedToSend:totalUnitCount];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    ZWTSessionTaskDelegate *delegate = [self delegateForTask:task];
    
    // delegate may be nil when completing a task in the background
    if (delegate) {
        [delegate URLSession:session task:task didCompleteWithError:error];
        
        [self removeDelegateForTask:task];
    }
}
#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    ZWTSessionTaskDelegate *delegate = [self delegateForTask:downloadTask];
    if (delegate) {
        [delegate URLSession:session downloadTask:downloadTask didFinishDownloadingToURL:location];
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    ZWTSessionTaskDelegate *delegate = [self delegateForTask:downloadTask];
    [delegate URLSession:session downloadTask:downloadTask didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    ZWTSessionTaskDelegate *delegate = [self delegateForTask:downloadTask];
    [delegate URLSession:session downloadTask:downloadTask didResumeAtOffset:fileOffset expectedTotalBytes:expectedTotalBytes];

}

@end
