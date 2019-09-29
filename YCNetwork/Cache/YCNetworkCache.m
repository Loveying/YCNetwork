//
//  YCNetworkCache.m
//  YCNetworkDemo
//
//  Created by xiayingying on 2019/9/29.
//  Copyright © 2019 xyy. All rights reserved.
//

#import "YCNetworkCache.h"
#import "YCNetworkCache+Internal.h"

@interface YCNetworkCachePackage : NSObject <NSCoding>
@property (nonatomic, strong) id<NSCoding> object;
@property (nonatomic, strong) NSDate *updateDate;
@end
@implementation YCNetworkCachePackage
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    self.object = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(object))];
    self.updateDate = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(updateDate))];
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.object forKey:NSStringFromSelector(@selector(object))];
    [aCoder encodeObject:self.updateDate forKey:NSStringFromSelector(@selector(updateDate))];
}
@end


static NSString * const YCNetworkCacheName = @"YCNetworkCacheName";
static YYDiskCache *_diskCache = nil;
static YYMemoryCache *_memoryCache = nil;

@implementation YCNetworkCache

#pragma mark - life cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.writeMode = YCNetworkCacheWriteModeNone;
        self.readMode = YCNetworkCacheReadModeNone;
        self.ageSeconds = 0;
        self.extraCacheKey = [@"v" stringByAppendingString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    }
    return self;
}

#pragma mark - public

+ (NSInteger)getDiskCacheSize {
    return [YCNetworkCache.diskCache totalCost] / 1024.0 / 1024.0;
}

+ (void)removeDiskCache {
    [YCNetworkCache.diskCache removeAllObjects];
}

+ (void)removeMemeryCache {
    [YCNetworkCache.memoryCache removeAllObjects];
}

#pragma mark - internal

- (void)setObject:(id<NSCoding>)object forKey:(id)key {
    if (self.writeMode == YCNetworkCacheWriteModeNone) return;
    
    YCNetworkCachePackage *package = [YCNetworkCachePackage new];
    package.object = object;
    package.updateDate = [NSDate date];
    
    if (self.writeMode & YCNetworkCacheWriteModeMemory) {
        [YCNetworkCache.memoryCache setObject:package forKey:key];
    }
    if (self.writeMode & YCNetworkCacheWriteModeDisk) {
        [YCNetworkCache.diskCache setObject:package forKey:key withBlock:^{}]; //子线程执行，空闭包仅为了去除警告
    }
}

- (void)objectForKey:(NSString *)key withBlock:(nonnull void (^)(NSString * _Nonnull, id<NSCoding> _Nullable))block {
    if (!block) return;
    
    void(^callBack)(id<NSCoding>) = ^(id<NSCoding> obj) {
        YCNETWORK_MAIN_QUEUE_ASYNC(^{
            if (obj && [((NSObject *)obj) isKindOfClass:YCNetworkCachePackage.class]) {
                YCNetworkCachePackage *package = (YCNetworkCachePackage *)obj;
                if (self.ageSeconds != 0 && -[package.updateDate timeIntervalSinceNow] > self.ageSeconds) {
                    block(key, nil);
                } else {
                    block(key, package.object);
                }
            } else {
                block(key, nil);
            }
        })
    };
    
    id<NSCoding> object = [YCNetworkCache.memoryCache objectForKey:key];
    if (object) {
        callBack(object);
    } else {
        [YCNetworkCache.diskCache objectForKey:key withBlock:^(NSString *key, id<NSCoding> object) {
            if (object && ![YCNetworkCache.memoryCache objectForKey:key]) {
                [YCNetworkCache.memoryCache setObject:object forKey:key];
            }
            callBack(object);
        }];
    }
}

#pragma mark - getter and setter

+ (YYDiskCache *)diskCache {
    if (!_diskCache) {
        NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        NSString *path = [cacheFolder stringByAppendingPathComponent:YCNetworkCacheName];
        _diskCache = [[YYDiskCache alloc] initWithPath:path];
    }
    return _diskCache;
}

+ (void)setDiskCache:(YYDiskCache *)diskCache {
    _diskCache = diskCache;
}

+ (YYMemoryCache *)memoryCache {
    if (!_memoryCache) {
        _memoryCache = [YYMemoryCache new];
        _memoryCache.name = YCNetworkCacheName;
    }
    return _memoryCache;
}

+ (void)setMemoryCache:(YYMemoryCache *)memoryCache {
    _memoryCache = memoryCache;
}

@end

