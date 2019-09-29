//
//  YCNetworkCache+Internal.h
//  YCNetworkDemo
//
//  Created by xiayingying on 2019/9/29.
//  Copyright © 2019 xyy. All rights reserved.
//

#import "YCNetworkCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface YCNetworkCache ()

/**
 存数据
 
 @param object 数据对象
 @param key 标识
 */
- (void)setObject:(nullable id<NSCoding>)object forKey:(id)key;

/**
 取数据
 
 @param key 标识
 @param block 回调 (主线程)
 */
- (void)objectForKey:(NSString *)key withBlock:(void(^)(NSString *key, id<NSCoding> _Nullable object))block;

@end
NS_ASSUME_NONNULL_END
