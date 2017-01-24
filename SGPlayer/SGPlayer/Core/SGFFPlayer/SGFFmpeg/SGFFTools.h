//
//  SGFFTools.h
//  SGMediaKit
//
//  Created by Single on 19/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFDecoder.h"

#define SGFFSynLog(...)
//#define SGFFSynLog(...)          NSLog(__VA_ARGS__)
#define SGFFThreadLog(...)
//#define SGFFThreadLog(...)       NSLog(__VA_ARGS__)
#define SGFFPacketLog(...)
//#define SGFFPacketLog(...)       NSLog(__VA_ARGS__)
#define SGFFSleepLog(...)
//#define SGFFSleepLog(...)        NSLog(__VA_ARGS__)
#define SGFFDecodeLog(...)
//#define SGFFDecodeLog(...)       NSLog(__VA_ARGS__)
#define SGFFErrorLog(...)
//#define SGFFErrorLog(...)        NSLog(__VA_ARGS__)

void sg_ff_log(void * context, int level, const char * format, va_list args);

NSError * sg_ff_check_error(int result);
NSError * sg_ff_check_error_code(int result, SGFFDecoderErrorCode errorCode);

void sg_ff_convert_AVFrame_to_YUV(UInt8 * src, int linesize, int width, int height, UInt8 ** dst, int * lenght);

double sg_ff_get_timebase(AVStream * stream, double default_timebase);
double sg_ff_get_fps(AVStream * stream, double timebase);
