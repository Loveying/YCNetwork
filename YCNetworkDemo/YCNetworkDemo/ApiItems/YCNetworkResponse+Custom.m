//
//  YCNetworkResponse+Custom.m
//  YCNetworkDemo
//
//  Created by Codyy.YY on 2020/1/3.
//  Copyright © 2020 xyy. All rights reserved.
//

#import "YCNetworkResponse+Custom.h"
#import <objc/runtime.h>

@implementation YCNetworkResponse (Custom)

static void const *YCNetworkResponseErrorTypeKey = &YCNetworkResponseErrorTypeKey;
- (void)setErrorType:(YCResponseErrorType)errorType {
    objc_setAssociatedObject(self, YCNetworkResponseErrorTypeKey, @(errorType), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (YCResponseErrorType)errorType {
    NSNumber *tmp = objc_getAssociatedObject(self, YCNetworkResponseErrorTypeKey);
    return tmp.integerValue;
}


@end
