//
//  YCNetworkDefine.h
//  YCNetworkDemo
//
//  Created by xiayingying on 2019/9/29.
//  Copyright © 2019 xyy. All rights reserved.
//

#ifndef YCNetworkDefine_h
#define YCNetworkDefine_h

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif


#define YCNETWORK_QUEUE_ASYNC(queue, block)\
if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(queue)) == 0) {\
block();\
} else {\
dispatch_async(queue, block);\
}

#define YCNETWORK_MAIN_QUEUE_ASYNC(block) YCNETWORK_QUEUE_ASYNC(dispatch_get_main_queue(), block)


NS_ASSUME_NONNULL_BEGIN

/// 请求类型
typedef NS_ENUM(NSInteger, YCRequestMethod) {
    YCRequestMethodGET,
    YCRequestMethodPOST,
    YCRequestMethodDELETE,
    YCRequestMethodPUT,
    YCRequestMethodHEAD,
    YCRequestMethodPATCH
};

/// 缓存存储模式
typedef NS_OPTIONS(NSUInteger, YCNetworkCacheWriteMode) {
    /// 无缓存
    YCNetworkCacheWriteModeNone = 0,
    /// 内存缓存
    YCNetworkCacheWriteModeMemory = 1 << 0,
    /// 磁盘缓存
    YCNetworkCacheWriteModeDisk = 1 << 1,
    YCNetworkCacheWriteModeMemoryAndDisk = YCNetworkCacheWriteModeMemory | YCNetworkCacheWriteModeDisk
};

/// 缓存读取模式
typedef NS_ENUM(NSInteger, YCNetworkCacheReadMode) {
    /// 不读取缓存
    YCNetworkCacheReadModeNone,
    /// 缓存命中后仍然发起网络请求
    YCNetworkCacheReadModeAlsoNetwork,
    /// 缓存命中后不发起网络请求
    YCNetworkCacheReadModeCancelNetwork,
};

/// 网络请求释放策略
typedef NS_ENUM(NSInteger, YCNetworkReleaseStrategy) {
    /// 网络任务会持有 YCBaseRequest 实例，网络任务完成 YCBaseRequest 实例才会释放
    YCNetworkReleaseStrategyHoldRequest,
    /// 网络请求将随着 YCBaseRequest 实例的释放而取消
    YCNetworkReleaseStrategyWhenRequestDealloc,
    /// 网络请求和 YCBaseRequest 实例无关联
    YCNetworkReleaseStrategyNotCareRequest
};

/// 重复网络请求处理策略
typedef NS_ENUM(NSInteger, YCNetworkRepeatStrategy) {
    /// 允许重复网络请求
    YCNetworkRepeatStrategyAllAllowed,
    /// 取消最旧的网络请求
    YCNetworkRepeatStrategyCancelOldest,
    /// 取消最新的网络请求
    YCNetworkRepeatStrategyCancelNewest
};

/// 网络请求回调重定向类型
typedef NS_ENUM(NSInteger, YCRequestRedirection) {
    /// 重定向为成功
    YCRequestRedirectionSuccess,
    /// 重定向为失败
    YCRequestRedirectionFailure,
    /// 停止后续操作（主要是停止回调）
    YCRequestRedirectionStop
};


@class YCBaseRequest;
@class YCNetworkResponse;


/// 进度闭包
typedef void(^YCRequestProgressBlock)(NSProgress *progress);

/// 缓存命中闭包
typedef void(^YCRequestCacheBlock)(YCNetworkResponse *response);

/// 请求成功闭包
typedef void(^YCRequestSuccessBlock)(YCNetworkResponse *response);

/// 请求失败闭包
typedef void(^YCRequestFailureBlock)(YCNetworkResponse *response);


/// 网络请求响应代理
@protocol YCResponseDelegate <NSObject>
@optional

/// 上传进度
- (void)request:(__kindof YCBaseRequest *)request uploadProgress:(NSProgress *)progress;

/// 下载进度
- (void)request:(__kindof YCBaseRequest *)request downloadProgress:(NSProgress *)progress;

/// 缓存命中
- (void)request:(__kindof YCBaseRequest *)request cacheWithResponse:(YCNetworkResponse *)response;

/// 请求成功
- (void)request:(__kindof YCBaseRequest *)request successWithResponse:(YCNetworkResponse *)response;

/// 请求失败
- (void)request:(__kindof YCBaseRequest *)request failureWithResponse:(YCNetworkResponse *)response;

@end

NS_ASSUME_NONNULL_END

#endif /* YCNetworkDefine_h */
