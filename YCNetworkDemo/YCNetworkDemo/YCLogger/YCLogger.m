//
//  YCLogger.m
//  YCNetworkDemo
//
//  Created by xiayingying on 2019/9/29.
//  Copyright © 2019 YCy. All rights reserved.
//

#import "YCLogger.h"

static BOOL __enableLog__ ;
static dispatch_queue_t __logQueue__ ;

@implementation YCLogger

+ (void)initialize {
#ifdef DEBUG
    __enableLog__ = YES;
#else
    __enableLog__ = NO;
#endif
    __logQueue__ = dispatch_queue_create("com.YC.log", DISPATCH_QUEUE_SERIAL);
}

+ (BOOL)isLoggerEnabled {
    __block BOOL enable = NO;
    dispatch_sync(__logQueue__, ^{
        enable = __enableLog__;
    });
    return enable;
}

+ (void)enableLog:(BOOL)enableLog {
    dispatch_sync(__logQueue__, ^{
        __enableLog__ = enableLog;
    });
}

+ (instancetype)sharedLogger {
    static id sharedLogger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLogger = [[self alloc] init];
    });
    return sharedLogger;
}

+ (void)log:(BOOL)asynchronous
      level:(NSInteger)level
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
     format:(NSString *)format, ... {
    @try {
        va_list args;
        va_start(args, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        [self.sharedLogger log:asynchronous message:message level:level file:file function:function line:line];
        va_end(args);
        
    } @catch (NSException *exception) {
        
    }
    
}

- (void)log:(BOOL)asynchronous
    message:(NSString *)message
      level:(NSInteger)level
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line {
    @try{
        NSString *logMessage = [[NSString alloc]initWithFormat:@"[YCLogger][%@]  %s [line %lu]    %s %@",[self descriptionForLevel:level],function,(unsigned long)line,[@"" UTF8String],message];
        if (__enableLog__) {
            NSLog(@"%@",logMessage);
        }
    } @catch(NSException *exception){
        
    }
}

- (NSString *)descriptionForLevel:(YCLoggerLevel)level {
    NSString *desc = nil;
    switch (level) {
        case YCLoggerLevelInfo:
            desc = @"INFO";
            break;
        case YCLoggerLevelWarning:
            desc = @"⚠️ WARN";
            break;
        case YCLoggerLevelError:
            desc = @"❌ ERROR";
            break;
        default:
            desc = @"UNKNOW";
            break;
    }
    return desc;
}


@end

