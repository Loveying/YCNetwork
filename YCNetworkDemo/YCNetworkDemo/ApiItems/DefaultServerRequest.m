//
//  DefaultServerRequest.m
//  YCNetworkDemo
//
//  Created by xiayingying on 2019/9/29.
//  Copyright © 2019 YCy. All rights reserved.
//

#import "DefaultServerRequest.h"
#import <YCBaseRequest+Internal.h>
#import "YCLogger.h"
#import "Api.h"

@interface DefaultServerRequest()

@property (nonatomic,strong) NSMutableString *logStr;

@end

@implementation DefaultServerRequest

#pragma mark - life cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.baseURI = @"https://www.apiopen.top";
        self.requestSerializer = [AFHTTPRequestSerializer serializer];
        self.requestSerializer.timeoutInterval = 25;
        self.responseSerializer = [AFJSONResponseSerializer serializer];
        [self.cacheHandler setShouldCacheBlock:^BOOL(YCNetworkResponse * _Nonnull response) {
            // 检查数据正确性，保证缓存有用的内容
            return YES;
        }];
        [self.logStr appendString:@"\n*******************************\n \t\trequest start \n*******************************\n\n"];
    }
    return self;
}

#pragma mark - ovveride

- (NSDictionary *)yc_preprocessParameter:(NSDictionary *)parameter {
    NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:parameter ?: @{}];
    [self.logStr appendString:[NSString stringWithFormat:@"request parameter: %@\n",[self jsonStrWithData:parameter]]];
    return tmp;
}

- (NSString *)yc_preprocessURLString:(NSString *)URLString {
    
    [self.logStr appendString:[NSString stringWithFormat:@"request url: %@\n",URLString]];
    return URLString;
}

- (void)yc_preprocessSuccessInMainThreadWithResponse:(YCNetworkResponse *)response {
    [self.logStr appendString:[NSString stringWithFormat:@"request response: %@\n",[self jsonStrWithData:response.responseObject]]];
    [self.logStr appendString:@"\n*******************************\n \t\trequest end \n*******************************\n\n"];
    YCLog(@"%@",self.logStr);

}

- (void)yc_preprocessFailureInMainThreadWithResponse:(YCNetworkResponse *)response {
    [self.logStr appendString:[NSString stringWithFormat:@"request error: %@\n",response.error]];
    [self.logStr appendString:@"\n*******************************\n \t\trequest end \n*******************************\n\n"];
    YCLog(@"%@",self.logStr);
    
}

- (NSString *)requestBaseUri {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *tmpUri = [defaults objectForKey:BaseUriIdentifier];
    switch ([tmpUri integerValue]) {
        case 1:  return BaseDevUri;
        case 2:  return BaseTestUri;
        case 3:  return BaseProUri;
        default: return BaseTestUri;
    }
}

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
