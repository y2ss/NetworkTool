//
//  RegisterApi.m
//  NetWorkTool
//
//  Created by y2ss on 2018/10/25.
//  Copyright © 2018年 y2ss. All rights reserved.
//

#import "RegisterApi.h"

@interface RegisterApi() {
    NSString *_username;
    NSString *_password;
    NSString *_code;
}

@end

@implementation RegisterApi

- (instancetype)initWithUsername:(NSString *)username password:(NSString *)password code:(NSString *)code {
    if (self = [super init]) {
        _username = username;
        _password = password;
        _code = code;
    }
    return self;
}

- (NSString *)pathURL {
    return @"/user/register";
}

- (SSBasicRequestMethod)requestMethod {
    return SSBasicRequestMethodPost;
}

- (id)paramater {
    return @{
             @"username":_username,
             @"password":_password,
             @"code":_code
             };
}

- (SSRequestSerializerType)requestSerializerType {
    return SSRequestSerializerTypeJSON;
}

@end
