//
//  ViewController.m
//  ZWTSessionDemo
//
//  Created by joywii on 15/2/5.
//  Copyright (c) 2015年 joywii. All rights reserved.
//

#import "ViewController.h"
#import "ZWTHTTPRequest.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *getButton = [UIButton buttonWithType:UIButtonTypeCustom];
    getButton.frame = CGRectMake(50, 50, 100, 50);
    getButton.backgroundColor = [UIColor redColor];
    [getButton addTarget:self action:@selector(getButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [getButton setTitle:@"GET" forState:UIControlStateNormal];
    [self.view addSubview:getButton];
    
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
@end
