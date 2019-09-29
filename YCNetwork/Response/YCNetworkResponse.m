//
//  YCNetworkResponse.m
//  YCNetworkDemo
//
//  Created by xiayingying on 2019/9/29.
//  Copyright © 2019 xyy. All rights reserved.
//

#import "YCNetworkResponse.h"

@interface YCNetworkResponse()

@property (nonatomic, strong) NSURLSessionTask *sessionTask;

@property (nonatomic, strong) NSError *error;

@end

@implementation YCNetworkResponse

#pragma mark - life cycle

+ (instancetype)responseWithSessionTask:(NSURLSessionTask *)sessionTask responseObject:(id)responseObject error:(NSError *)error {
    YCNetworkResponse *response = [YCNetworkResponse new];
    response.sessionTask = sessionTask;
    response.responseObject = responseObject;
    response.error = error;
    return response;
}

#pragma mark - getter

- (NSHTTPURLResponse *)URLResponse {
    if (!self.sessionTask || ![self.sessionTask.response isKindOfClass:NSHTTPURLResponse.class]) {
        return nil;
    }
    return (NSHTTPURLResponse *)self.sessionTask.response;
}


@end
