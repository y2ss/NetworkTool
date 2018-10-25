//
//  SSHTTPUtils.h
//  NetWorkTool
//
//  Created by y2ss on 2018/10/24.
//  Copyright © 2018年 y2ss. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SSBasicRequest;
@interface SSHTTPUtils : NSObject

+ (NSString *)md5StringFromString:(NSString *)string;

+ (NSStringEncoding)stringEncodingWithRequest:(SSBasicRequest *)request;

+ (BOOL)validateJSON:(id)json withValidator:(id)jsonValidator;

@end
