//
//  YCNetworkManager.h
//  YCNetworkDemo
//
//  Created by xiayingying on 2019/9/29.
//  Copyright © 2019 xyy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YCBaseRequest.h"
#import "YCNetworkResponse.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^YCRequestCompletionBlock)(YCNetworkResponse *response);

@interface YCNetworkManager : NSObject

+ (instancetype)sharedManager;

- (nullable NSNumber *)startNetworkingWithRequest:(YCBaseRequest *)request
                                   uploadProgress:(nullable YCRequestProgressBlock)uploadProgress
                                 downloadProgress:(nullable YCRequestProgressBlock)downloadProgress
                                       completion:(nullable YCRequestCompletionBlock)completion;

- (void)cancelNetworkingWithSet:(NSSet<NSNumber *> *)set;

- (instancetype)init OBJC_UNAVAILABLE("use '+sharedManager' instead");
+ (instancetype)new OBJC_UNAVAILABLE("use '+sharedManager' instead");

@end

NS_ASSUME_NONNULL_END
