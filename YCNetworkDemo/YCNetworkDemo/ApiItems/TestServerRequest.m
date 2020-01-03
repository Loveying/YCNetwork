//
//  TestServerRequest.m
//  YCNetworkDemo
//
//  Created by Codyy.YY on 2020/1/3.
//  Copyright © 2020 xyy. All rights reserved.
//

#import "TestServerRequest.h"
#import <YCBaseRequest+Internal.h>
#import "YCNetworkResponse+Custom.h"
#import "YCLogger.h"

@interface TestServerRequest()

@property (nonatomic,strong) NSMutableString *logStr;

@end

@implementation TestServerRequest

#pragma mark - life cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.baseURI = @"http://japi.juhe.cn";
        [self.cacheHandler setShouldCacheBlock:^BOOL(YCNetworkResponse * _Nonnull response) {
            // 检查数据正确性，保证缓存有用的内容
            return YES;
        }];
    }
    return self;
}

#pragma mark - ovveride

- (AFHTTPRequestSerializer *)requestSerializer {
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer new];
    serializer.timeoutInterval = 25;
    return serializer;
}

- (AFHTTPResponseSerializer *)responseSerializer {
    AFHTTPResponseSerializer *serializer = [AFJSONResponseSerializer serializer];
    NSMutableSet *types = [NSMutableSet set];
    [types addObject:@"text/html"];
    [types addObject:@"text/plain"];
    [types addObject:@"application/json"];
    [types addObject:@"text/json"];
    [types addObject:@"text/javascript"];
    serializer.acceptableContentTypes = types;
    return serializer;
}

- (void)start {
    [self.logStr appendString:@"\n*******************************\n \t\trequest start \n*******************************\n\n"];
    [super start];
}

- (void)yc_redirection:(void (^)(YCRequestRedirection))redirection response:(YCNetworkResponse *)response {
    
    // 处理错误的状态码
    if (response.error) {
        YCResponseErrorType errorType;
        switch (response.error.code) {
            case NSURLErrorTimedOut:
                errorType = YCResponseErrorTypeTimedOut;
                break;
            case NSURLErrorCancelled:
                errorType = YCResponseErrorTypeCancelled;
                break;
            default:
                errorType = YCResponseErrorTypeNoNetwork;
                break;
        }
        response.errorType = errorType;
    }
    
    // 自定义重定向
    NSDictionary *responseDic = response.responseObject;
    if ([[NSString stringWithFormat:@"%@", responseDic[@"error_code"]] isEqualToString:@"2"]) {
        redirection(YCRequestRedirectionFailure);
        response.errorType = YCResponseErrorTypeServerError;
        return;
    }
    //redirection(YCRequestRedirectionFailure);
    redirection(YCRequestRedirectionSuccess);
}

- (NSDictionary *)yc_preprocessParameter:(NSDictionary *)parameter {
    NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:parameter ?: @{}];
    tmp[@"test_deviceID"] = @"test250";  //给每一个请求，添加额外的参数
    //[self.logStr appendString:[NSString stringWithFormat:@"request parameter: %@\n",[self jsonStrWithData:tmp]]];
    NSLog(@"----Parameter----");
    return tmp;
}


- (NSDictionary *)yc_preprocessHeaderParameter:(NSDictionary *)parameter {
    NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:parameter ?: @{}];
    /// 设置公共请求头参数
    [tmp setValue:@"1.2.1" forKey:@"version"];
    [tmp setValue:@"ios" forKey:@"platform"];
    return tmp;
}


- (NSString *)yc_preprocessURLString:(NSString *)URLString {
    
    //[self.logStr appendString:[NSString stringWithFormat:@"request url: %@\n",URLString]];
    NSLog(@"----URLString----");
    return URLString;
}

- (void)yc_preprocessSuccessInChildThreadWithResponse:(YCNetworkResponse *)response {
    NSMutableDictionary *res = [NSMutableDictionary dictionaryWithDictionary:response.responseObject];
    //res[@"test_user"] = @"夏夏"; //为每一个返回结果添加字段
    response.responseObject = res;
}

- (void)yc_preprocessSuccessInMainThreadWithResponse:(YCNetworkResponse *)response {
    [self.logStr appendString:[NSString stringWithFormat:@"request response: %@\n",[self jsonStrWithData:response.responseObject]]];
    [self.logStr appendString:@"\n*******************************\n \t\trequest end \n*******************************\n\n"];
    YCLog(@"%@",self.logStr);

}

- (void)yc_preprocessFailureInChildThreadWithResponse:(YCNetworkResponse *)response {
    
}

- (void)yc_preprocessFailureInMainThreadWithResponse:(YCNetworkResponse *)response {
    [self.logStr appendString:[NSString stringWithFormat:@"request error: %@\n",response.error]];
    [self.logStr appendString:@"\n*******************************\n \t\trequest end \n*******************************\n\n"];
    YCLog(@"%@",self.logStr);
    
}

//- (NSString *)requestBaseUri {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSString *tmpUri = [defaults objectForKey:BaseUriIdentifier];
//    switch ([tmpUri integerValue]) {
//        case 1:  return BaseDevUri;
//        case 2:  return BaseTestUri;
//        case 3:  return BaseProUri;
//        default: return BaseTestUri;
//    }
//}

- (NSMutableString *)logStr
{
    if (!_logStr) {
        _logStr = [[NSMutableString alloc] init];
    }
    return _logStr;
}

- (NSString *)jsonStrWithData:(id)data {
    if (!data) return nil;
    BOOL validate = [NSJSONSerialization isValidJSONObject:data];
    if (!validate) return nil;
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&parseError];
    if (parseError) {
        return nil;
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
