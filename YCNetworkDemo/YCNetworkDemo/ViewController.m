//
//  ViewController.m
//  YCNetworkDemo
//
//  Created by xiayingying on 2019/9/29.
//  Copyright © 2019 YCy. All rights reserved.
//

#import "ViewController.h"
#import "TestViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.bounds = CGRectMake(0, 0, 300, 100);
    button.center = CGPointMake(self.view.center.x, 200 + 100);
    button.titleLabel.font = [UIFont boldSystemFontOfSize:30];
    [button setTitle:@"测试网络" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
}

#pragma mark - event
- (void)clickButton:(UIButton *)button {
    TestViewController *testVC = [[TestViewController alloc] init];
    [self.navigationController pushViewController:testVC animated:true];
}

@end
