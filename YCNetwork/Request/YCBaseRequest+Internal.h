//
//  YCBaseRequest+Internal.h
//  YCNetworkDemo
//
//  Created by xiayingying on 2019/9/29.
//  Copyright © 2019 xyy. All rights reserved.
//

#import "YCBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface YCBaseRequest ()

/// 请求方法字符串
- (NSString *)requestMethodString;

/// 请求 URL 字符串
- (NSString *)validRequestURLString;

/// 请求参数字符串
- (id)validRequestParameter;

@end


NS_ASSUME_NONNULL_END
