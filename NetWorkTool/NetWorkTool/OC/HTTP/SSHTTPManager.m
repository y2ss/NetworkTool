//
//  SSHTTPManager.m
//  NetWorkTool
//
//  Created by y2ss on 2018/10/23.
//  Copyright © 2018年 y2ss. All rights reserved.
//

#import "SSHTTPManager.h"
#import "SSBasicRequest.h"
#import "SSHTTPConfig.h"
#import <pthread/pthread.h>
#import "SSHTTPPrivate.h"
#import "SSHTTPUtils.h"

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)
#define ACCEPT_CODE [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(100, 500)]

static SSHTTPManager *__instance = nil;
NSString *const SSRequestValidationErrorDomain = @"com.ss.request.validation";

@interface SSHTTPManager() {
    NSMutableDictionary <NSNumber *, SSBasicRequest *> *_requestLists;
    pthread_mutex_t _lock;
}

@property (nonatomic, strong) AFHTTPSessionManager *manager;
@property (nonatomic, strong) SSHTTPConfig *config;

@end

@implementation SSHTTPManager

+ (SSHTTPManager *)manager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __instance = [[SSHTTPManager alloc] init];
    });
    return __instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _config = [SSHTTPConfig sharedConfig];
        _manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:_config.sessionConfiguration];
        _requestLists = @{}.mutableCopy;
        pthread_mutex_init(&_lock, NULL);
        _manager.securityPolicy = _config.securityPolicy;
        _manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        _manager.responseSerializer.acceptableStatusCodes = ACCEPT_CODE;
    }
    return self;
}

- (void)addRequest:(SSBasicRequest *)request {
    NSParameterAssert(request != nil);
    NSError * __autoreleasing requestSerializationError = nil;
    request.requestTask = [self startRequestWith:request error:&requestSerializationError];
    if (requestSerializationError) {
        [self handleFailed:request error:requestSerializationError];
        return;
    }
    
    [self addRequestToRecord:request];
    [request.requestTask resume];
}

- (void)cancelRequest:(SSBasicRequest *)request {
    if (request.resumeDataDownloadPath) {
        NSURLSessionDownloadTask *task = (NSURLSessionDownloadTask *)request.requestTask;
        [task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            NSURL *localURL = [self incompleteDownloadTempPathForDownloadPath:request.resumeDataDownloadPath];
            [resumeData writeToURL:localURL atomically:YES];
        }];
    } else {
        [request.requestTask cancel];
    }
    [self removeRequestFromRecord:request];
    [request clearBlock];
}

- (void)cancelAllRequests {
    Lock();
    NSArray *allKeys = [_requestLists allKeys];
    Unlock();
    if (allKeys && allKeys.count > 0) {
        NSArray *copiedKeys = [allKeys copy];
        for (NSNumber *key in copiedKeys) {
            Lock();
            SSBasicRequest *request = _requestLists[key];
            Unlock();
            [request stop];
        }
    }
}

- (NSURLSessionTask *)startRequestWith:(SSBasicRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    NSString *url = [self buildRequestURL:request];
    AFHTTPRequestSerializer *requestSerializer = [self requestSerializerWith:request];
    id param = [request paramater];
    switch ([request requestMethod]) {
        case SSBasicRequestMethodGet:
            if (request.resumeDataDownloadPath) {
                return [self downloadTaskWithDownloadPath:request.resumeDataDownloadPath requestSerializer:requestSerializer URLString:url params:param progress:request.downloadProgressBlock error:error];
            } else {
                return [self dataTaskWithHTTPMethod:@"GET" requestSerializer:requestSerializer URLString:url params:param error:error];
            }
            break;
        case SSBasicRequestMethodPost:
            return [self dataTaskWithHTTPMethod:@"POST" requestSerializer:requestSerializer URLString:url params:param multipartFormDataBlock:[request multipartFormDataBlock] error:error];
            break;
    }
}

- (NSURLSessionDownloadTask *)downloadTaskWithDownloadPath:(NSString *)downloadPath
                                         requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                                 URLString:(NSString *)URLString
                                                    params:(id)params
                                                  progress:(nullable void(^)(NSProgress *downloadProgress))downloadProgressBlock
                                                     error:(NSError * _Nullable __autoreleasing *)error {
    
    NSMutableURLRequest *request = [requestSerializer requestWithMethod:@"GET" URLString:URLString parameters:params error:error];
    
    NSString *downloadTargetPath;
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:downloadPath isDirectory:&isDirectory]) {
        isDirectory = NO;
    }
    if (isDirectory) {
        NSString *fileName = [request.URL lastPathComponent];
        downloadTargetPath = [NSString pathWithComponents:@[downloadPath, fileName]];
    } else {
        downloadTargetPath = downloadPath;
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadTargetPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:downloadTargetPath error:nil];
    }
    
    BOOL resumeDataFileExists = [[NSFileManager defaultManager] fileExistsAtPath:[self incompleteDownloadTempPathForDownloadPath:downloadPath].path];
    NSData *data = [NSData dataWithContentsOfURL:[self incompleteDownloadTempPathForDownloadPath:downloadPath]];
    BOOL resumeSucceeded = NO;
    __block NSURLSessionDownloadTask *downloadTask = nil;
    if (resumeDataFileExists) {
        @try {
            downloadTask = [_manager downloadTaskWithResumeData:data progress:downloadProgressBlock destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
            } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                [self handleDataTaskResult:downloadTask response:response responseObject:filePath error:error];
            }];
            resumeSucceeded = YES;
        } @catch(NSException *exception) {
            NSLog(@"resume download failed, reason = %@", exception.reason);
            resumeSucceeded = NO;
        }
    }
    if (!resumeSucceeded) {
        downloadTask = [_manager downloadTaskWithRequest:request progress:downloadProgressBlock destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            [self handleDataTaskResult:downloadTask response:response responseObject:filePath error:error];
        }];
    }
    return downloadTask;
}

- (NSString *)buildRequestURL:(SSBasicRequest *)request {
    NSParameterAssert(request != nil);
    
    NSString *detailURL = [request pathURL];
    NSURL *temp = [NSURL URLWithString:detailURL];
    if (temp && temp.host && temp.scheme) {
        return detailURL;
    }
    NSString *baseURL = nil;
    if ([request baseURL] && [request baseURL].length > 0) {
        baseURL = [request baseURL];
    } else {
        baseURL = [_config baseURL];
    }
    NSParameterAssert(baseURL != nil);
    NSParameterAssert(![baseURL isEqualToString:@""]);
    
    NSURL *url = [NSURL URLWithString:baseURL];
    if (baseURL.length > 0 && [baseURL hasPrefix:@"/"]) {
        url = [url URLByAppendingPathComponent:@""];
    }
    
    return [NSURL URLWithString:detailURL relativeToURL:url].absoluteString;
}

- (AFHTTPRequestSerializer *)requestSerializerWith:(SSBasicRequest *)request {
    AFHTTPRequestSerializer *requestSerializer = nil;
    if (request.requestSerializerType == SSRequestSerializerTypeHTTP) {
        requestSerializer = [AFHTTPRequestSerializer serializer];
    } else {
        requestSerializer = [AFJSONRequestSerializer serializer];
    }
    requestSerializer.timeoutInterval = [request timeoutInterval];
    requestSerializer.allowsCellularAccess = [request allowsCellularAccess];
    
    NSDictionary *header = [request header];
    [header enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [requestSerializer setValue:obj forHTTPHeaderField:key];
    }];
    return requestSerializer;
}

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                   URLString:(NSString *)URLString
                                      params:(id)params
                                       error:(NSError * _Nullable __autoreleasing *)error {
    return [self dataTaskWithHTTPMethod:method requestSerializer:requestSerializer URLString:URLString params:params multipartFormDataBlock:nil error:error];
}

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                          params:(id)params
                          multipartFormDataBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                                           error:(NSError * _Nullable __autoreleasing *)error {
    NSMutableURLRequest *request = nil;
    if (block) {
        request = [requestSerializer multipartFormRequestWithMethod:method URLString:URLString parameters:params constructingBodyWithBlock:block error:error];
    } else {
        request = [requestSerializer requestWithMethod:method URLString:URLString parameters:params error:error];
    }
    
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [_manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable _error) {
        [self handleDataTaskResult:dataTask response:response responseObject:responseObject error:_error];
    }];
    return dataTask;
}

- (void)handleDataTaskResult:(NSURLSessionTask *)task response:(NSURLResponse *)response responseObject:(id)responseObject error:(NSError *)error {
    Lock();
    SSBasicRequest *request = _requestLists[@(task.taskIdentifier)];
    Unlock();
    
    NSError *requestError = nil;
    NSError *__autoreleasing serializationError = nil;
    request.responseObject = responseObject;
    
    if ([request.responseObject isKindOfClass:[NSData class]]) {
        request.responseData = responseObject;
        request.responseString = [[NSString alloc] initWithData:responseObject encoding:[SSHTTPUtils stringEncodingWithRequest:request]];
        
        switch (request.responseSerializerType) {
            case SSResponseSerializerTypeHTTP:
                // Default serializer. Do nothing.
                break;
            case SSResponseSerializerTypeJSON: {
                AFJSONResponseSerializer *jrs = [AFJSONResponseSerializer serializer];
                jrs.acceptableStatusCodes = ACCEPT_CODE;
                request.responseObject = [jrs responseObjectForResponse:task.response data:request.responseData error:&serializationError];
                request.responseJSON = request.responseObject;
            }
                break;
            default:
                break;
        }
    }

    BOOL success = NO;
    NSError * __autoreleasing validationError = nil;
    if (error) {
        requestError = error;
    } else if (serializationError) {
        requestError = serializationError;
    } else {
        success = [self validateResult:request error:&validationError];
        requestError = validationError;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self handleResponse:request success:success error:error];
    });
}

- (NSURL *)incompleteDownloadTempPathForDownloadPath:(NSString *)downloadPath {
    NSString *tempPath = nil;
    NSString *md5 = [SSHTTPUtils md5StringFromString:downloadPath];
    tempPath = [[self incompleteDownloadTempCacheFolder] stringByAppendingPathComponent:md5];;
    return [NSURL fileURLWithPath:tempPath];
}

- (NSString *)incompleteDownloadTempCacheFolder {
    NSFileManager *fileManager = [NSFileManager new];
    static NSString *cacheFolder;
    
    if (!cacheFolder) {
        NSString *cacheDir = NSTemporaryDirectory();
        cacheFolder = [cacheDir stringByAppendingPathComponent:@"fragment"];
    }
    NSError *error = nil;
    if (![fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSLog(@"failed to create cache directory at %@", cacheFolder);
        cacheFolder = nil;
    }
    return cacheFolder;
}

- (void)handleResponse:(SSBasicRequest *)request success:(BOOL)success error:(NSError *)error {
    if ([request.delegate respondsToSelector:@selector(requestWillStop:)]) {
        [request.delegate requestWillStop:request];
    }
    if (success) {
        if ([request.delegate respondsToSelector:@selector(requestSuccessed:)]) {
            [request.delegate requestSuccessed:request];
        }
        if (request.successBlock) {
            request.successBlock(request);
        }
    } else {
        [self handleFailed:request error:error];
    }
    if ([request.delegate respondsToSelector:@selector(requestDidStop:)]) {
        [request.delegate requestDidStop:request];
    }
    
    [self removeRequestFromRecord:request];
    [request clearBlock];
}

- (void)handleFailed:(SSBasicRequest *)request error:(NSError *)error {
    if ([request.delegate respondsToSelector:@selector(requestFailed:error:)]) {
        [request.delegate requestFailed:request error:error];
    }
    if (request.failureBlock) {
        request.failureBlock(request, error);
    }
    
    NSData *incompleteDownloadData = error.userInfo[NSURLSessionDownloadTaskResumeData];
    if (incompleteDownloadData && request.resumeDataDownloadPath) {
        [incompleteDownloadData writeToURL:[self incompleteDownloadTempPathForDownloadPath:request.resumeDataDownloadPath] atomically:YES];
    }
    
    if ([request.responseObject isKindOfClass:[NSURL class]]) {
        NSURL *url = request.responseObject;
        if (url.isFileURL && [[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
            request.responseData = [NSData dataWithContentsOfURL:url];
            request.responseString = [[NSString alloc] initWithData:request.responseData encoding:[SSHTTPUtils stringEncodingWithRequest:request]];
        }
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
    }
    request.responseObject = nil;
}

- (void)addRequestToRecord:(SSBasicRequest *)request {
    Lock();
    _requestLists[@(request.requestTask.taskIdentifier)] = request;
    Unlock();
}

- (void)removeRequestFromRecord:(SSBasicRequest *)request {
    Lock();
    [_requestLists removeObjectForKey:@(request.requestTask.taskIdentifier)];
    Unlock();
}

#pragma mark - validate result
- (BOOL)validateResult:(SSBasicRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    BOOL result = [request statusCodeValidator];
    if (!result) {
        if (error) {
            *error = [NSError errorWithDomain:SSRequestValidationErrorDomain code:-333 userInfo:@{NSLocalizedDescriptionKey:@"Invalid status code"}];
            return result;
        }
    }
    id json = [request responseJSON];
    id validator = [request jsonValidator];
    if (json && validator) {
        result = [SSHTTPUtils validateJSON:json withValidator:validator];
        if (!result) {
            if (error) {
                *error = [NSError errorWithDomain:SSRequestValidationErrorDomain code:-334 userInfo:@{NSLocalizedDescriptionKey:@"Invalid JSON format"}];
            }
            return result;
        }
    }
    return YES;
}


@end
