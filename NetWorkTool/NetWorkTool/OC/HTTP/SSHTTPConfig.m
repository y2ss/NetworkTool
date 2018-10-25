//
//  SSHTTPConfig.m
//  NetWorkTool
//
//  Created by y2ss on 2018/10/23.
//  Copyright © 2018年 y2ss. All rights reserved.
//

#import "SSHTTPConfig.h"
#import <AFNetworking/AFNetworking.h>

static SSHTTPConfig *__instance = nil;

@implementation SSHTTPConfig

+ (SSHTTPConfig *)sharedConfig {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __instance = [[SSHTTPConfig alloc] init];
    });
    return __instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _baseURL = @"";
        _securityPolicy = [AFSecurityPolicy defaultPolicy];
    }
    return self;
}

- (void)setBaseURL:(NSString *)baseURL {
    _baseURL = baseURL;
}

@end
