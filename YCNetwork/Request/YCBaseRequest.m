//
//  YCBaseRequest.m
//  YCNetworkDemo
//
//  Created by xiayingying on 2019/9/29.
//  Copyright © 2019 xyy. All rights reserved.
//

#import "YCBaseRequest.h"
#import "YCBaseRequest+Internal.h"
#import "YCNetworkManager.h"
#import "YCNetworkCache+Internal.h"
#import <pthread/pthread.h>

#define YCN_IDECORD_LOCK(...) \
pthread_mutex_lock(&self->_lock); \
__VA_ARGS__ \
pthread_mutex_unlock(&self->_lock);

@interface YCBaseRequest ()
@property (nonatomic, copy, nullable) YCRequestProgressBlock uploadProgress;
@property (nonatomic, copy, nullable) YCRequestProgressBlock downloadProgress;
@property (nonatomic, copy, nullable) YCRequestCacheBlock cacheBlock;
@property (nonatomic, copy, nullable) YCRequestSuccessBlock successBlock;
@property (nonatomic, copy, nullable) YCRequestFailureBlock failureBlock;
@property (nonatomic, strong) YCNetworkCache *cacheHandler;
/// 记录网络任务标识容器
@property (nonatomic, strong) NSMutableSet<NSNumber *> *taskIDRecord;
@end

@implementation YCBaseRequest {
    pthread_mutex_t _lock;
}

#pragma mark - life cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        pthread_mutex_init(&_lock, NULL);
        self.releaseStrategy = YCNetworkReleaseStrategyHoldRequest;
        self.repeatStrategy = YCNetworkRepeatStrategyAllAllowed;
        self.taskIDRecord = [NSMutableSet set];
    }
    return self;
}

- (void)dealloc {
    if (self.releaseStrategy == YCNetworkReleaseStrategyWhenRequestDealloc) {
        [self cancel];
    }
    pthread_mutex_destroy(&_lock);
}

#pragma mark - public

- (void)startWithSuccess:(YCRequestSuccessBlock)success failure:(YCRequestFailureBlock)failure {
    [self startWithUploadProgress:nil downloadProgress:nil cache:nil success:success failure:failure];
}

- (void)startWithCache:(YCRequestCacheBlock)cache success:(YCRequestSuccessBlock)success failure:(YCRequestFailureBlock)failure {
    [self startWithUploadProgress:nil downloadProgress:nil cache:cache success:success failure:failure];
}

- (void)startWithUploadProgress:(YCRequestProgressBlock)uploadProgress downloadProgress:(YCRequestProgressBlock)downloadProgress cache:(YCRequestCacheBlock)cache success:(YCRequestSuccessBlock)success failure:(YCRequestFailureBlock)failure {
    self.uploadProgress = uploadProgress;
    self.downloadProgress = downloadProgress;
    self.cacheBlock = cache;
    self.successBlock = success;
    self.failureBlock = failure;
    [self start];
}

- (void)start {
    if (self.isExecuting) {
        switch (self.repeatStrategy) {
            case YCNetworkRepeatStrategyCancelNewest: return;
            case YCNetworkRepeatStrategyCancelOldest: {
                [self cancelNetworking];
            }
                break;
            default: break;
        }
    }
    
    NSString *cacheKey = [self requestCacheKey];

    if (self.cacheHandler.readMode == YCNetworkCacheReadModeNone) {
        [self startWithCacheKey:cacheKey];
        return;
    }
    
    [self.cacheHandler objectForKey:cacheKey withBlock:^(NSString * _Nonnull key, id<NSCoding>  _Nonnull object) {
        if (object) { //缓存命中
            YCNetworkResponse *response = [YCNetworkResponse responseWithSessionTask:nil responseObject:object error:nil];
            [self successWithResponse:response cacheKey:cacheKey fromCache:YES taskID:nil];
        }
        
        BOOL needRequestNetwork = !object || self.cacheHandler.readMode == YCNetworkCacheReadModeAlsoNetwork;
        if (needRequestNetwork) {
            [self startWithCacheKey:cacheKey];
        } else {
            [self clearRequestBlocks];
        }
    }];
}

- (void)cancel {
    self.delegate = nil;
    [self clearRequestBlocks];
    [self cancelNetworking];
}

- (void)cancelNetworking {
    //此处取消顺序很重要
    YCN_IDECORD_LOCK(
        NSSet *removeSet = self.taskIDRecord.mutableCopy;
        [self.taskIDRecord removeAllObjects];
    )
    [[YCNetworkManager sharedManager] cancelNetworkingWithSet:removeSet];
}

- (BOOL)isExecuting {
    YCN_IDECORD_LOCK(BOOL isExecuting = self.taskIDRecord.count > 0;)
    return isExecuting;
}

- (void)clearRequestBlocks {
    self.uploadProgress = nil;
    self.downloadProgress = nil;
    self.cacheBlock = nil;
    self.successBlock = nil;
    self.failureBlock = nil;
}

#pragma mark - request

- (void)startWithCacheKey:(NSString *)cacheKey {
    __weak typeof(self) weakSelf = self;
    BOOL(^cancelled)(NSNumber *) = ^BOOL(NSNumber *taskID){
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return YES;
        YCN_IDECORD_LOCK(BOOL contains = [self.taskIDRecord containsObject:taskID];)
        return !contains;
    };
    
    __block NSNumber *taskID = nil;
    if (self.releaseStrategy == YCNetworkReleaseStrategyHoldRequest) {
        taskID = [[YCNetworkManager sharedManager] startNetworkingWithRequest:self uploadProgress:^(NSProgress * _Nonnull progress) {
            if (cancelled(taskID)) return;
            [self requestUploadProgress:progress];
        } downloadProgress:^(NSProgress * _Nonnull progress) {
            if (cancelled(taskID)) return;
            [self requestDownloadProgress:progress];
        } completion:^(YCNetworkResponse * _Nonnull response) {
            if (cancelled(taskID)) return;
            [self requestCompletionWithResponse:response cacheKey:cacheKey fromCache:NO taskID:taskID];
        }];
    } else {
        __weak typeof(self) weakSelf = self;
        taskID = [[YCNetworkManager sharedManager] startNetworkingWithRequest:weakSelf uploadProgress:^(NSProgress * _Nonnull progress) {
            if (cancelled(taskID)) return;
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            [self requestUploadProgress:progress];
        } downloadProgress:^(NSProgress * _Nonnull progress) {
            if (cancelled(taskID)) return;
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            [self requestDownloadProgress:progress];
        } completion:^(YCNetworkResponse * _Nonnull response) {
            if (cancelled(taskID)) return;
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            [self requestCompletionWithResponse:response cacheKey:cacheKey fromCache:NO taskID:taskID];
        }];
    }
    if (nil != taskID) {
        YCN_IDECORD_LOCK([self.taskIDRecord addObject:taskID];)
    }
}

#pragma mark - response

- (void)requestUploadProgress:(NSProgress *)progress {
    YCNETWORK_MAIN_QUEUE_ASYNC(^{
        if ([self.delegate respondsToSelector:@selector(request:uploadProgress:)]) {
            [self.delegate request:self uploadProgress:progress];
        }
        if (self.uploadProgress) {
            self.uploadProgress(progress);
        }
    })
}

- (void)requestDownloadProgress:(NSProgress *)progress {
    YCNETWORK_MAIN_QUEUE_ASYNC(^{
        if ([self.delegate respondsToSelector:@selector(request:downloadProgress:)]) {
            [self.delegate request:self downloadProgress:progress];
        }
        if (self.downloadProgress) {
            self.downloadProgress(progress);
        }
    })
}

- (void)requestCompletionWithResponse:(YCNetworkResponse *)response cacheKey:(NSString *)cacheKey fromCache:(BOOL)fromCache taskID:(NSNumber *)taskID {
    void(^process)(YCRequestRedirection) = ^(YCRequestRedirection redirection) {
        switch (redirection) {
            case YCRequestRedirectionSuccess: {
                [self successWithResponse:response cacheKey:cacheKey fromCache:NO taskID:taskID];
            }
                break;
            case YCRequestRedirectionFailure: {
                [self failureWithResponse:response taskID:taskID];
            }
                break;
            case YCRequestRedirectionStop:
            default: {
                YCN_IDECORD_LOCK([self.taskIDRecord removeObject:taskID];)
            }
                break;
        }
    };
    
    if ([self respondsToSelector:@selector(yc_redirection:response:)]) {
        [self yc_redirection:process response:response];
    } else {
        YCRequestRedirection redirection = response.error ? YCRequestRedirectionFailure : YCRequestRedirectionSuccess;
        process(redirection);
    }
}

- (void)successWithResponse:(YCNetworkResponse *)response cacheKey:(NSString *)cacheKey fromCache:(BOOL)fromCache taskID:(NSNumber *)taskID {
    
    if ([self respondsToSelector:@selector(yc_preprocessSuccessInChildThreadWithResponse:)]) {
        [self yc_preprocessSuccessInChildThreadWithResponse:response];
    }
    
    YCNETWORK_MAIN_QUEUE_ASYNC(^{
        if ([self respondsToSelector:@selector(yc_preprocessSuccessInMainThreadWithResponse:)]) {
            [self yc_preprocessSuccessInMainThreadWithResponse:response];
        }
        
        if (fromCache) {
            if ([self.delegate respondsToSelector:@selector(request:cacheWithResponse:)]) {
                [self.delegate request:self cacheWithResponse:response];
            }
            if (self.cacheBlock) {
                self.cacheBlock(response);
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(request:successWithResponse:)]) {
                [self.delegate request:self successWithResponse:response];
            }
            if (self.successBlock) {
                self.successBlock(response);
            }
            [self clearRequestBlocks];
            // 在网络响应数据被业务处理完成后进行缓存，可避免将异常数据写入缓存（比如数据导致 Crash 的情况）
            BOOL shouldCache = !self.cacheHandler.shouldCacheBlock || self.cacheHandler.shouldCacheBlock(response);
            BOOL isSendFile = self.requestConstructingBody || self.downloadPath.length > 0;
            if (!isSendFile && shouldCache) {
                [self.cacheHandler setObject:response.responseObject forKey:cacheKey];
            }
        }
        
        if (taskID) [self.taskIDRecord removeObject:taskID];
    })
}

- (void)failureWithResponse:(YCNetworkResponse *)response taskID:(NSNumber *)taskID {
    if ([self respondsToSelector:@selector(yc_preprocessFailureInChildThreadWithResponse:)]) {
        [self yc_preprocessFailureInChildThreadWithResponse:response];
    }
    
    YCNETWORK_MAIN_QUEUE_ASYNC(^{
        if ([self respondsToSelector:@selector(yc_preprocessFailureInMainThreadWithResponse:)]) {
            [self yc_preprocessFailureInMainThreadWithResponse:response];
        }
        
        if ([self.delegate respondsToSelector:@selector(request:failureWithResponse:)]) {
            [self.delegate request:self failureWithResponse:response];
        }
        if (self.failureBlock) {
            self.failureBlock(response);
        }
        [self clearRequestBlocks];
        
        if (taskID) [self.taskIDRecord removeObject:taskID];
    })
}

#pragma mark - private

- (NSString *)requestIdentifier {
    NSString *identifier = [NSString stringWithFormat:@"%@-%@%@", [self requestMethodString], [self validRequestURLString], [self stringFromParameter:[self validRequestParameter]]];
    return identifier;
}

- (NSString *)requestCacheKey {
    NSString *cacheKey = [NSString stringWithFormat:@"%@%@", self.cacheHandler.extraCacheKey, [self requestIdentifier]];
    if (self.cacheHandler.customCacheKeYClock) {
        cacheKey = self.cacheHandler.customCacheKeYClock(cacheKey);
    }
    return cacheKey;
}

- (NSString *)stringFromParameter:(NSDictionary *)parameter {
    NSMutableString *string = [NSMutableString string];
    NSArray *allKeys = [parameter.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [[NSString stringWithFormat:@"%@", obj1] compare:[NSString stringWithFormat:@"%@", obj2] options:NSLiteralSearch];
    }];
    for (id key in allKeys) {
        [string appendString:[NSString stringWithFormat:@"%@%@=%@", string.length > 0 ? @"&" : @"?", key, parameter[key]]];
    }
    return string;
}

- (NSString *)requestMethodString {
    switch (self.requestMethod) {
        case YCRequestMethodGET: return @"GET";
        case YCRequestMethodPOST: return @"POST";
        case YCRequestMethodPUT: return @"PUT";
        case YCRequestMethodDELETE: return @"DELETE";
        case YCRequestMethodHEAD: return @"HEAD";
        case YCRequestMethodPATCH: return @"PATCH";
    }
}

- (NSString *)validRequestURLString {
    NSURL *baseURL = [NSURL URLWithString:self.baseURI];
    NSString *URLString = [NSURL URLWithString:self.requestURI relativeToURL:baseURL].absoluteString;
    if ([self respondsToSelector:@selector(yc_preprocessURLString:)]) {
        URLString = [self yc_preprocessURLString:URLString];
    }
    return URLString;
}

- (id)validRequestParameter {
    id parameter = self.requestParameter;
    if ([self respondsToSelector:@selector(yc_preprocessParameter:)]) {
        parameter = [self yc_preprocessParameter:parameter];
    }
    return parameter;
}

- (id)validRequestHeaderParameter {
    id parameter = self.requestHeaderParameter;
    if ([self respondsToSelector:@selector(yc_preprocessHeaderParameter:)]) {
        parameter = [self yc_preprocessHeaderParameter:parameter];
    }
    return parameter;
}

#pragma mark - getter

- (YCNetworkCache *)cacheHandler {
    if (!_cacheHandler) {
        _cacheHandler = [YCNetworkCache new];
    }
    return _cacheHandler;
}

@end
