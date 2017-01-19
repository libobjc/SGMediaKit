//
//  SGFFTools.h
//  SGMediaKit
//
//  Created by Single on 19/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFDecoder.h"

void sg_ff_log(void * context, int level, const char * format, va_list args);

NSError * sg_ff_check_error(int result);
NSError * sg_ff_check_error_code(int result, SGFFDecoderErrorCode errorCode);

void sg_ff_convert_AVFrame_to_YUV(UInt8 * src, int linesize, int width, int height, UInt8 ** dst, int * lenght);

void sg_ff_get_AVStream_fps_timebase(AVStream * stream, NSTimeInterval defaultTimebase, NSTimeInterval * pFPS, NSTimeInterval * pTimebase);
