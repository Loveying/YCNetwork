//
//  YCLogger.h
//  YCNetworkDemo
//
//  Created by xiayingying on 2019/9/29.
//  Copyright © 2019 YCy. All rights reserved.
//

#import <Foundation/Foundation.h>

#define YCLog(fmt,...)\
YCLogLevel(YCLoggerLevelInfo,(fmt), ## __VA_ARGS__)

#define YCWarningLog(fmt,...)\
YCLogLevel(YCLoggerLevelWarning,(fmt), ## __VA_ARGS__)

#define YCErrorLog(fmt,...)\
YCLogLevel(YCLoggerLevelError,(fmt), ## __VA_ARGS__)

#define YCLogLevel(lvl,fmt,...)\
[YCLogger log : YES                                      \
level : lvl                                                  \
file : __FILE__                                            \
function : __PRETTY_FUNCTION__                       \
line : __LINE__                                           \
format : (fmt), ## __VA_ARGS__]

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger,YCLoggerLevel) {
    YCLoggerLevelInfo = 1,
    YCLoggerLevelWarning ,
    YCLoggerLevelError ,
};

@interface YCLogger : NSObject

@property (nonatomic,strong,readonly) YCLogger *sharedLogger;

+ (BOOL)isLoggerEnabled;

+ (void)enableLog:(BOOL)enableLog;// 默认DEBUG 开启Log

+ (void)log:(BOOL)asynchronous
      level:(NSInteger)level
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
     format:(NSString *)format, ... ;

@end

NS_ASSUME_NONNULL_END
