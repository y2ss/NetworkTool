//
//  SSHTTPPrivate.h
//  NetWorkTool
//
//  Created by y2ss on 2018/10/24.
//  Copyright © 2018年 y2ss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SSBasicRequest.h"

@interface SSBasicRequest (Setter)

@property (nonatomic, strong, readwrite) id responseObject;
@property (nonatomic, strong, readwrite) NSData *responseData;
@property (nonatomic, strong, readwrite) NSString *responseString;
@property (nonatomic, strong, readwrite) id responseJSON;
@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;
@property (nonatomic, strong, readwrite) NSHTTPURLResponse *response;

@end
