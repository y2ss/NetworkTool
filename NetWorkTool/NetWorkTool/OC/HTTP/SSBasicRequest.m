//
//  SSBasicRequest.m
//  NetWorkTool
//
//  Created by y2ss on 2018/10/23.
//  Copyright © 2018年 y2ss. All rights reserved.
//

#import "SSBasicRequest.h"
#import "SSHTTPManager.h"

@interface SSBasicRequest()

@property (nonatomic, strong, readwrite) id responseObject;
@property (nonatomic, strong, readwrite) NSData *responseData;
@property (nonatomic, strong, readwrite) NSString *responseString;
@property (nonatomic, strong, readwrite) id responseJSON;
@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;
@property (nonatomic, strong, readwrite) NSHTTPURLResponse *response;
@property (nonatomic, strong, readwrite) NSError *error;

@end

@implementation SSBasicRequest

+ (instancetype)generate {
    return [[self alloc] init];
}

- (NSHTTPURLResponse *)response {
    return (NSHTTPURLResponse *)self.requestTask.response;
}

- (SSResponseSerializerType)responseSerializerType {
    return SSResponseSerializerTypeJSON;
}

- (SSRequestSerializerType)requestSerializerType {
    return SSRequestSerializerTypeHTTP;
}

- (id)paramater {
    return nil;
}

- (NSString *)baseURL {
    return @"";
}

- (NSString *)pathURL {
    return @"";
}

- (NSDictionary *)header {
    return nil;
}

- (NSTimeInterval)timeoutInterval {
    return 30;
}

- (BOOL)allowsCellularAccess {
    return YES;
}

- (BOOL)statusCodeValidator {
    NSInteger statusCode = [self responseStatusCode];
    return (statusCode >= 200 && statusCode <= 399);
}

- (NSInteger)responseStatusCode {
    return self.response.statusCode;
}

- (id)jsonValidator {
    return nil;
}

- (NSString *)resumeDataDownloadPath {
    return nil;
}

//break retain cycle
- (void)clearBlock {
    self.successBlock = nil;
    self.failureBlock = nil;
}

- (void)start {
    [[SSHTTPManager manager] addRequest:self];
}

- (void)stop {
    self.delegate = nil;
    [[SSHTTPManager manager] cancelRequest:self];
}

- (void)sendRequest {
    [self sendRequestWithCompletedBlockWithSuccess:nil failure:nil];
}

- (void)sendRequestWithCompletedBlockWithSuccess:(SSRequestSuccessBlock)success
                                         failure:(SSRequestFailureBlock)failure {
    self.successBlock = success;
    self.failureBlock = failure;
    [self start];
}

@end
