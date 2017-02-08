//
//  SGFFTools.h
//  SGMediaKit
//
//  Created by Single on 19/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFDecoder.h"

#define SGFFSynLogEnable        0
#define SGFFThreadLogEnable     0
#define SGFFPacketLogEnable     0
#define SGFFSleepLogEnable      0
#define SGFFDecodeLogEnable     0
#define SGFFErrorLogEnable      0

#if SGFFSynLogEnable
#define SGFFSynLog(...)          NSLog(__VA_ARGS__)
#else
#define SGFFSynLog(...)
#endif

#if SGFFThreadLogEnable
#define SGFFThreadLog(...)       NSLog(__VA_ARGS__)
#else
#define SGFFThreadLog(...)
#endif

#if SGFFPacketLogEnable
#define SGFFPacketLog(...)       NSLog(__VA_ARGS__)
#else
#define SGFFPacketLog(...)
#endif

#if SGFFSleepLogEnable
#define SGFFSleepLog(...)        NSLog(__VA_ARGS__)
#else
#define SGFFSleepLog(...)
#endif

#if SGFFDecodeLogEnable
#define SGFFDecodeLog(...)       NSLog(__VA_ARGS__)
#else
#define SGFFDecodeLog(...)
#endif

#if SGFFErrorLogEnable
#define SGFFErrorLog(...)        NSLog(__VA_ARGS__)
#else
#define SGFFErrorLog(...)
#endif

void sg_ff_log(void * context, int level, const char * format, va_list args);

NSError * sg_ff_check_error(int result);
NSError * sg_ff_check_error_code(int result, SGFFDecoderErrorCode errorCode);

void sg_ff_convert_AVFrame_to_YUV(UInt8 * src, int linesize, int width, int height, UInt8 ** dst, int * lenght);

double sg_ff_get_timebase(AVStream * stream, double default_timebase);
double sg_ff_get_fps(AVStream * stream, double timebase);
