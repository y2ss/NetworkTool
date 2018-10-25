//
//  RegisterApi.h
//  NetWorkTool
//
//  Created by y2ss on 2018/10/25.
//  Copyright © 2018年 y2ss. All rights reserved.
//

#import "SSBasicRequest.h"

@interface RegisterApi : SSBasicRequest

- (instancetype)initWithUsername:(NSString *)username password:(NSString *)password code:(NSString *)code;

@end
