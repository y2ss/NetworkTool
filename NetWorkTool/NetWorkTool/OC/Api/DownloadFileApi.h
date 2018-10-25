//
//  DownloadFileApi.h
//  NetWorkTool
//
//  Created by y2ss on 2018/10/25.
//  Copyright © 2018年 y2ss. All rights reserved.
//

#import "SSBasicRequest.h"

@interface DownloadFileApi : SSBasicRequest

- (instancetype)initWithSavePath:(NSString *)path;

@end
