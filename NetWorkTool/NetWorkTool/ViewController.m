//
//  ViewController.m
//  NetWorkTool
//
//  Created by y2ss on 2018/9/9.
//  Copyright © 2018年 y2ss. All rights reserved.
//

#import "ViewController.h"
#import "NetWorkTool-Swift.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    

    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)onSwift:(id)sender {

    SwiftViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"SwiftViewController"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)onOC:(id)sender {
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
