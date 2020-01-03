//
//  YCNetworkResponse+Custom.h
//  YCNetworkDemo
//
//  Created by Codyy.YY on 2020/1/3.
//  Copyright © 2020 xyy. All rights reserved.
//


#import <YCNetwork/YCNetworkResponse.h>

NS_ASSUME_NONNULL_BEGIN

/// 网络响应错误类型
typedef NS_ENUM(NSInteger, YCResponseErrorType) {
    /// 未知
    YCResponseErrorTypeUnknown,
    /// 超时
    YCResponseErrorTypeTimedOut,
    /// 取消
    YCResponseErrorTypeCancelled,
    /// 无网络
    YCResponseErrorTypeNoNetwork,
    /// 服务器错误
    YCResponseErrorTypeServerError,
    /// 登录状态过期
    YCResponseErrorTypeLoginExpired
};

@interface YCNetworkResponse (Custom)

/// 请求失败类型 (使用该属性做业务处理足够)
@property (nonatomic, assign) YCResponseErrorType errorType;

@end

NS_ASSUME_NONNULL_END
