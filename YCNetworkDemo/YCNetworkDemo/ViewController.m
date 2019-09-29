//
//  ViewController.m
//  YCNetworkDemo
//
//  Created by xiayingying on 2019/9/29.
//  Copyright © 2019 YCy. All rights reserved.
//

#import "ViewController.h"
#import "DefaultServerRequest.h"
#import "OtherServerRequest.h"

@interface ViewController ()<YCResponseDelegate>

@property (nonatomic, strong) DefaultServerRequest *requestA;

@property (nonatomic, strong) DefaultServerRequest *requestB;

@property (nonatomic,strong) OtherServerRequest *requestC;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [@[@"搜索小说", @"搜索天气",@"图片上传"] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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
        [self searchNovel];
        [self searchWeather];
    } else if(button.tag == 1){
        [self searchWeather];
    }else {
        // [self uploadImage];
    }
}

- (void)searchNovel {
    
    [self.requestA startWithSuccess:^(YCNetworkResponse * _Nonnull response) {
        YCNETWORK_MAIN_QUEUE_ASYNC(^{
            NSLog(@"--- %d",[[NSThread currentThread] isMainThread]);
        })
    } failure:^(YCNetworkResponse * _Nonnull response) {
        
    }];
    
}

- (void)searchWeather {
    [self.requestB startWithSuccess:^(YCNetworkResponse * _Nonnull response) {
        YCNETWORK_MAIN_QUEUE_ASYNC(^{
            NSLog(@"--- %d",[[NSThread currentThread] isMainThread]);
        })
    } failure:^(YCNetworkResponse * _Nonnull response) {
        
    }];
}

- (void)uploadImage {
    UIImage *imag;
    NSArray<UIImage *> *photos = @[imag];
    self.requestC.requestConstructingBody = ^(id<AFMultipartFormData>  _Nonnull formData) {
        for (int i = 0; i < photos.count; i ++) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            NSString *fileName = [NSString stringWithFormat:@"%@.jpg",str];
            UIImage *image = photos[i];
            NSData *imageData = UIImageJPEGRepresentation(image, 0.28);
            [formData appendPartWithFileData:imageData name:[NSString stringWithFormat:@"upload%d",i+1] fileName:fileName mimeType:@"image/jpeg"];
        }
    };
}
#pragma mark - YCResponseDelegate
- (void)request:(__kindof YCBaseRequest *)request uploadProgress:(NSProgress *)progress {
    
}

- (void)request:(__kindof YCBaseRequest *)request successWithResponse:(YCNetworkResponse *)response {
    
}

- (void)request:(__kindof YCBaseRequest *)request failureWithResponse:(YCNetworkResponse *)response {
    
}

#pragma mark - getter

- (DefaultServerRequest *)requestA {
    if (!_requestA) {
        _requestA = [[DefaultServerRequest alloc] init];
        _requestA.requestMethod = YCRequestMethodGET;
        _requestA.requestURI = @"novelSearchApi";
        _requestA.requestParameter = @{@"name":@"盗墓笔记"};
    }
    return _requestA;
}

- (DefaultServerRequest *)requestB {
    if (!_requestB) {
        _requestB = [[DefaultServerRequest alloc] init];
        _requestB.requestMethod = YCRequestMethodGET;
        _requestB.requestURI = @"weatherApi";
        _requestB.requestParameter = @{@"city":@"北京"};
    }
    return _requestB;
}

- (OtherServerRequest *)requestC
{
    if (!_requestC) {
        _requestC = [[OtherServerRequest alloc] init];
        _requestC.requestURI = @"uploadImage";
        _requestC.delegate = self;
    }
    return _requestC;
}
@end
