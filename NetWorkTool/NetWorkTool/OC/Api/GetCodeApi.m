//
//  GetCodeApi.m
//  NetWorkTool
//
//  Created by y2ss on 2018/10/25.
//  Copyright © 2018年 y2ss. All rights reserved.
//

#import "GetCodeApi.h"

@implementation GetCodeApi

- (NSString *)pathURL {
    return @"/user/code";
}

- (id)paramater {
    return @{
             @"username":@"18328035630"
             };
}

- (SSBasicRequestMethod)requestMethod {
    return SSBasicRequestMethodGet;
}


@end
