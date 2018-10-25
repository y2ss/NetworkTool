//
//  SSHTTPConfig.h
//  NetWorkTool
//
//  Created by y2ss on 2018/10/23.
//  Copyright © 2018年 y2ss. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AFSecurityPolicy;
@interface SSHTTPConfig : NSObject

@property (nonatomic, readonly) NSString *baseURL;
@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;

+ (SSHTTPConfig *)sharedConfig;

- (void)setBaseURL:(NSString *)baseURL;

@end
