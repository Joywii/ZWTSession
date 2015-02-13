//
//  AppDelegate.h
//  ZWTSessionDemo
//
//  Created by joywii on 15/2/5.
//  Copyright (c) 2015年 joywii. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (copy) void (^backgroundURLSessionCompletionHandler)();


@end

