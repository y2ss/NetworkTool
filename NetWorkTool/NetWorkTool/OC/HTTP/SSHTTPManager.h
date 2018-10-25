//
//  SSHTTPManager.h
//  NetWorkTool
//
//  Created by y2ss on 2018/10/23.
//  Copyright © 2018年 y2ss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@class SSBasicRequest;
@interface SSHTTPManager : NSObject

+ (SSHTTPManager *)manager;

- (void)addRequest:(SSBasicRequest *)request;

- (void)cancelRequest:(SSBasicRequest *)request;
- (void)cancelAllRequests;

@end
