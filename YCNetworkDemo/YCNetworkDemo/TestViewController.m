//
//  TestViewController.m
//  YCNetworkDemo
//
//  Created by Codyy.YY on 2020/1/3.
//  Copyright © 2020 xyy. All rights reserved.
//

#import "TestViewController.h"
#import "TestServerRequest.h"

@interface TestViewController ()<YCResponseDelegate>
@property (nonatomic, strong) TestServerRequest *request;

@end

@implementation TestViewController

#pragma mark - life cycle

- (void)dealloc {
    NSLog(@"释放：%@", self);
    if (_request) [_request cancel];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [@[@"调用接口A", @"调用接口B"] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.bounds = CGRectMake(0, 0, 300, 100);
        button.center = CGPointMake(self.view.center.x, 200 + 100 * (idx + 1));
        button.tag = idx;
        button.titleLabel.font = [UIFont boldSystemFontOfSize:30];
        [button setTitle:obj forState:UIControlStateNormal];
        [button addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    }];

}

#pragma mark - event

- (void)clickButton:(UIButton *)button {
    if (button.tag == 0) {
        [self searchA];
    } else {
        [self searchB];
    }
}

#pragma mark - request

- (void)searchA {
    
    TestServerRequest *request = [TestServerRequest new];
    request.cacheHandler.writeMode = YCNetworkCacheWriteModeMemoryAndDisk;
    request.cacheHandler.readMode = YCNetworkCacheReadModeNone;
    request.requestMethod = YCRequestMethodGET;
    request.requestURI = @"charconvert/change.from";
    request.requestParameter = @{@"key":@"0e27c575047e83b407ff9e517cde9c76", @"type":@"2", @"text":@"呵呵呵呵"};
    request.requestHeaderParameter = @{@"header":@"value1"};
    __weak typeof(self) weakSelf = self;
    [request startWithCache:^(YCNetworkResponse * _Nonnull response) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        NSLog(@"\ncache success : %@", response.responseObject);
    } success:^(YCNetworkResponse * _Nonnull response) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        NSLog(@"\nresponse success : %@", response.responseObject);
    } failure:^(YCNetworkResponse * _Nonnull response) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        NSLog(@"\nresponse failure : 类型 : %@", @(response.errorType));
    }];
}

- (void)searchB {
    [self.request start];
}

#pragma mark - <YBResponseDelegate>

- (void)request:(__kindof YCBaseRequest *)request successWithResponse:(YCNetworkResponse *)response {
    NSLog(@"\nresponse success : %@", response.responseObject);
}

- (void)request:(__kindof YCBaseRequest *)request failureWithResponse:(YCNetworkResponse *)response {
    NSLog(@"\nresponse failure : 类型 : %@", @(response.errorType));
}

#pragma mark - getter

- (TestServerRequest *)request {
    if (!_request) {
        _request = [TestServerRequest new];
        _request.delegate = self;
        _request.requestMethod = YCRequestMethodGET;
        _request.requestURI = @"charconvert/change.from";
        _request.requestParameter = @{@"key":@"0e27c575047e83b407ff9e517cde9c76", @"type":@"2", @"text":@"哈哈哈哈"};
        _request.repeatStrategy = YCNetworkRepeatStrategyCancelOldest;        
    }
    return _request;
}


@end
