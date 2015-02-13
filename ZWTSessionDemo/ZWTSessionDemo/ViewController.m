//
//  ViewController.m
//  ZWTSessionDemo
//
//  Created by joywii on 15/2/5.
//  Copyright (c) 2015年 joywii. All rights reserved.
//

#import "ViewController.h"
#import "ZWTHTTPRequest.h"
#import "ZWTSessionManager.h"
#import "ZWTBackgroundRequest.h"
#import "AppDelegate.h"


@interface ViewController ()<ZWTBackgroundRequestDelegate>

@property (nonatomic,strong) ZWTSessionManager *sessionManager;

@property (strong, nonatomic) NSURLSessionDownloadTask *resumableTask;
@property (nonatomic, strong) NSData *resumeData;
@property (nonatomic, strong) NSProgress *progress;

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UILabel *progressLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *getButton = [UIButton buttonWithType:UIButtonTypeCustom];
    getButton.frame = CGRectMake(50, 50, 125, 50);
    getButton.backgroundColor = [UIColor redColor];
    [getButton addTarget:self action:@selector(getButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [getButton setTitle:@"GET" forState:UIControlStateNormal];
    [self.view addSubview:getButton];
    
    UIButton *uploadBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    uploadBackButton.frame = CGRectMake(50, 125, 125, 25);
    uploadBackButton.backgroundColor = [UIColor blackColor];
    [uploadBackButton addTarget:self action:@selector(uploadBackButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [uploadBackButton setTitle:@"UploadBack" forState:UIControlStateNormal];
    [self.view addSubview:uploadBackButton];
    
    UIButton *downloadBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    downloadBackButton.frame = CGRectMake(50, 160, 125, 25);
    downloadBackButton.backgroundColor = [UIColor blackColor];
    [downloadBackButton addTarget:self action:@selector(downloadBackButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [downloadBackButton setTitle:@"DownloadBack" forState:UIControlStateNormal];
    [self.view addSubview:downloadBackButton];
    
    UIButton *breakButton = [UIButton buttonWithType:UIButtonTypeCustom];
    breakButton.frame = CGRectMake(200, 50, 125, 50);
    breakButton.backgroundColor = [UIColor blueColor];
    [breakButton addTarget:self action:@selector(breakButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [breakButton setTitle:@"Resume" forState:UIControlStateNormal];
    [self.view addSubview:breakButton];
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelButton.frame = CGRectMake(200, 120, 125, 50);
    cancelButton.backgroundColor = [UIColor blueColor];
    [cancelButton addTarget:self action:@selector(cancelButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.view addSubview:cancelButton];
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(25, 200, 325, 400)];
    self.imageView.backgroundColor = [UIColor yellowColor];
    self.imageView.clipsToBounds = YES;
    [self.view addSubview:self.imageView];
    
    self.progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 620, 325, 25)];
    self.progressLabel.font = [UIFont systemFontOfSize:19];
    self.progressLabel.textColor = [UIColor blackColor];
    self.progressLabel.backgroundColor = [UIColor clearColor];
    self.progressLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.progressLabel];
}
- (void)dealloc
{
    if (self.progress) {
        [self.progress removeObserver:self forKeyPath:@"photoDownloadState" context:nil];
        [self.progress removeObserver:self forKeyPath:@"downloadProgress" context:nil];
    }
}
- (void)getButtonClick:(id)sender
{
    [[ZWTHTTPRequest shareRequest] GET:@"http://club.kuaizhan.com/apiv1/sites/8155653800/forums"
                            parameters:nil
                               success:^(NSURLSessionDataTask *task, id responseObject){
                                   NSLog(@"responseObject %@",responseObject);
                               }
                               failure:^(NSURLSessionDataTask *task, NSError *error) {
                                   
                               }];
}
- (void)uploadBackButtonClick:(id)sender
{
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.joywii.BackgroundUpload.BackgroundSession"];
    //TODO :
}
- (void)downloadBackButtonClick:(id)sender
{
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.joywii.BackgroundDownload.BackgroundSession"];
    ZWTBackgroundRequest *downloadBackRequest = [[ZWTBackgroundRequest alloc] initWithDelegate:self
                                                                         sessionConfiguration:config];
    NSURLSessionDownloadTask *downloadTast = [downloadBackRequest downloadBackground:@"http://farm3.staticflickr.com/2831/9823890176_82b4165653_b_d.jpg" parameters:nil progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        
        return [self destinationPath:targetPath];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        NSLog(@"back filePath: %@",filePath);
        if (filePath) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImage *image = [UIImage imageWithContentsOfFile:[filePath path]];
                self.imageView.image = image;
                self.imageView.contentMode = UIViewContentModeScaleAspectFill;
                self.imageView.hidden = NO;
            });
        }
    }];
    [downloadTast resume];
}
- (void)didFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.backgroundURLSessionCompletionHandler) {
        void (^handler)() = appDelegate.backgroundURLSessionCompletionHandler;
        appDelegate.backgroundURLSessionCompletionHandler = nil;
        handler();
    }
}
- (NSURL *)destinationPath:(NSURL *)targetPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *URLs = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsDirectory = URLs[0];
    NSURL *destinationPath = [documentsDirectory URLByAppendingPathComponent:[targetPath lastPathComponent]];
    return destinationPath;
}

- (void)breakButtonClick:(id)sender
{
    NSURL *(^destinationBlock)(NSURL *targetPath, NSURLResponse *response) = ^NSURL *(NSURL *targetPath, NSURLResponse *response){
        return [self destinationPath:targetPath];
    };
    
    void (^completeBlock)(NSURLResponse *response, NSURL *filePath, NSError *error) = ^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSLog(@"resume filePath: %@",filePath);
        if (filePath) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImage *image = [UIImage imageWithContentsOfFile:[filePath path]];
                self.imageView.image = image;
                self.imageView.contentMode = UIViewContentModeScaleAspectFill;
                self.imageView.hidden = NO;
            });
            self.resumeData = nil;
        }
        self.resumableTask = nil;
    };
    
    ZWTSessionManager *sessionManager = [[ZWTSessionManager alloc] initWithSessionConfiguration:nil];
    if (self.resumeData) {
        NSProgress *progress;
        self.resumableTask = [sessionManager downloadTaskWithResumeData:self.resumeData progress:&progress destination:destinationBlock completionHandler:completeBlock];
        self.progress = progress;
        [self addProgressObserver:self.progress];
        [self.resumableTask resume];
    } else {
        NSProgress *progerss;
        NSString *url = @"http://farm3.staticflickr.com/2846/9823925914_78cd653ac9_b_d.jpg";
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        self.resumableTask = [sessionManager downloadTaskWithRequest:request progress:&progerss destination:destinationBlock completionHandler:completeBlock];
        self.progress = progerss;
        [self addProgressObserver:self.progress];
        [self.resumableTask resume];
    }
}
- (void)cancelButtonClick:(id)sender
{
    if (self.resumableTask) {
        [self.resumableTask cancelByProducingResumeData:^(NSData *resumeData) {
            self.resumeData = resumeData;
            self.resumableTask = nil;
        }];
    }
}
- (void)addProgressObserver:(NSProgress *)progress
{
    [progress addObserver:self
               forKeyPath:@"completedUnitCount"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
    [progress addObserver:self
               forKeyPath:@"totalUnitCount"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
}
#pragma mark - KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"completedUnitCount"])
    {
        //更新状态
        int64_t  completedUnitCount = [(NSNumber *)[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        NSLog(@"completedUnitCount %lld",completedUnitCount);
        CGFloat progress = 100 * self.progress.completedUnitCount / self.progress.totalUnitCount;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressLabel.text = [NSString stringWithFormat:@"%f %%",progress];

        });
    }
    if ([keyPath isEqualToString:@"totalUnitCount"]) {
        int64_t  totalUnitCount = [(NSNumber *)[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        NSLog(@"totalUnitCount %lld",totalUnitCount);
        CGFloat progress = 100 * self.progress.completedUnitCount / self.progress.totalUnitCount;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressLabel.text = [NSString stringWithFormat:@"%f %%",progress];
            
        });
    }
}
@end
