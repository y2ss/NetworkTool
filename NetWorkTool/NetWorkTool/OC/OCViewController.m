//
//  OCViewController.m
//  NetWorkTool
//
//  Created by y2ss on 2018/10/25.
//  Copyright © 2018年 y2ss. All rights reserved.
//

#import "OCViewController.h"
#import "GetCodeApi.h"
#import "RegisterApi.h"
#import "DownloadFileApi.h"


@interface OCViewController () <SSBasicRequestDelegate>

@end

@implementation OCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //[self test1];
    [self test2];

}

- (void)test1 {
    GetCodeApi *api = [GetCodeApi generate];
    [api sendRequestWithCompletedBlockWithSuccess:^(SSBasicRequest * _Nonnull request) {
        NSDictionary *json = request.responseJSON;
        if ([json[@"code"] integerValue] == 0) {
            NSLog(@"%@", json[@"data"][@"code"]);
            [self registerText:json[@"data"][@"code"]];
        }
    } failure:^(SSBasicRequest * _Nonnull request, NSError * _Nonnull error) {
        NSLog(@"%@ %@", error, request);
    }];
}

- (void)test2 {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"video1.mp4"];
    NSLog(@"%@", path);
    DownloadFileApi *api = [[DownloadFileApi alloc] initWithSavePath:path];
    api.downloadProgressBlock = ^(NSProgress * _Nonnull progress) {
        NSLog(@"%f", progress.fractionCompleted);
    };
    [api sendRequestWithCompletedBlockWithSuccess:^(SSBasicRequest * _Nonnull request) {
        NSLog(@"%@", request.response);
    } failure:^(SSBasicRequest * _Nonnull request, NSError * _Nonnull error) {
        NSLog(@"%@", error);
    }];
}

- (void)registerText:(NSString *)code {
    RegisterApi *api = [[RegisterApi alloc] initWithUsername:@"18328035630" password:@"123456" code:code];
    api.delegate = self;
    [api sendRequest];
}

- (void)requestWillBegin:(SSBasicRequest *)request {
    NSLog(@"will begin");
}

- (void)requestWillStop:(SSBasicRequest *)request {
    NSLog(@"will stop");
}

- (void)requestDidStop:(SSBasicRequest *)request {
    NSLog(@"did stop");
}

- (void)requestSuccessed:(SSBasicRequest *)request {
    NSDictionary *json = request.responseJSON;
    NSLog(@"%ld", [json[@"code"] integerValue]);
}

- (void)requestFailed:(SSBasicRequest *)request error:(NSError *)error {
    NSLog(@"%@", error);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
