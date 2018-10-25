//
//  DownloadFileApi.m
//  NetWorkTool
//
//  Created by y2ss on 2018/10/25.
//  Copyright © 2018年 y2ss. All rights reserved.
//

#import "DownloadFileApi.h"

@implementation DownloadFileApi {
    NSString *_path;
}

- (instancetype)initWithSavePath:(NSString *)path {
    if (self = [super init]) {
        _path = path;
    }
    return self;
}

- (NSString *)pathURL {
    return @"/upload/video/video1.mp4";
}

- (NSString *)baseURL {
    return @"http://119.29.40.174:80";
}

- (NSString *)resumeDataDownloadPath {
    return _path;
}

@end
