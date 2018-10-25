//
//  SSBasicRequest.h
//  NetWorkTool
//
//  Created by y2ss on 2018/10/23.
//  Copyright © 2018年 y2ss. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SSBasicRequest;
@protocol AFMultipartFormData;

typedef NS_ENUM(NSUInteger, SSBasicRequestMethod) {
    SSBasicRequestMethodGet = 0,
    SSBasicRequestMethodPost,
};

typedef NS_ENUM(NSUInteger, SSRequestSerializerType) {
    SSRequestSerializerTypeHTTP = 0,
    SSRequestSerializerTypeJSON,
};

typedef NS_ENUM(NSUInteger, SSResponseSerializerType) {
    SSResponseSerializerTypeHTTP = 0,
    SSResponseSerializerTypeJSON,
};

typedef void (^ _Nullable SSRequestSuccessBlock)(SSBasicRequest *request);
typedef void (^ _Nullable SSRequestFailureBlock)(SSBasicRequest *request, NSError *error);
typedef void (^ _Nullable SSRequestMultipartFormDataBlock)(id<AFMultipartFormData> formData);
typedef void (^ _Nullable SSRequestProgressBlock)(NSProgress *progress);

@protocol SSBasicRequestDelegate<NSObject>
@optional
- (void)requestSuccessed:(SSBasicRequest *)request;
- (void)requestFailed:(SSBasicRequest *)request error:(NSError *)error;
- (void)requestWillBegin:(SSBasicRequest *)request;
- (void)requestWillStop:(SSBasicRequest *)request;
- (void)requestDidStop:(SSBasicRequest *)request;

@end

@interface SSBasicRequest : NSObject

@property (nonatomic, weak, nullable) id<SSBasicRequestDelegate> delegate;

@property (nonatomic, assign, readonly) SSBasicRequestMethod requestMethod;

@property (nonatomic, assign, readonly) SSRequestSerializerType requestSerializerType;

@property (nonatomic, readonly) SSResponseSerializerType responseSerializerType;

@property (nonatomic, strong, readonly, nullable) NSURLSessionTask *requestTask;

@property (nonatomic, strong, readonly, nullable) id responseObject;

@property (nonatomic, strong, readonly, nullable) NSData *responseData;

@property (nonatomic, strong, readonly, nullable) NSString *responseString;

@property (nonatomic, strong, readonly, nullable) id responseJSON;

@property (nonatomic, strong, readonly, nullable) NSHTTPURLResponse *response;

@property (nonatomic, strong, readonly, nullable) NSError *error;

@property (nonatomic, copy, nullable) SSRequestSuccessBlock successBlock;

@property (nonatomic, copy, nullable) SSRequestFailureBlock failureBlock;

@property (nonatomic, copy, nullable) SSRequestMultipartFormDataBlock multipartFormDataBlock;

@property (nonatomic, copy, nullable) SSRequestProgressBlock downloadProgressBlock;

+ (instancetype)generate;

- (id)paramater;

- (NSString *)pathURL;

- (NSString *)baseURL;

- (NSDictionary *)header;

- (NSTimeInterval)timeoutInterval;

- (BOOL)allowsCellularAccess;

- (BOOL)statusCodeValidator;

- (NSInteger)responseStatusCode;

- (id)jsonValidator;

//download path with resume data
- (NSString *)resumeDataDownloadPath;

- (void)clearBlock;

- (void)start;
- (void)stop;

- (void)sendRequest;
- (void)sendRequestWithCompletedBlockWithSuccess:(SSRequestSuccessBlock)success
                                         failure:(SSRequestFailureBlock)failure;

@end

NS_ASSUME_NONNULL_END

