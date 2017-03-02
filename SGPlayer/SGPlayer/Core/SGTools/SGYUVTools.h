//
//  SGYUVTools.h
//  SGMediaKit
//
//  Created by Single on 2017/3/2.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Foundation/Foundation.h>

size_t SGYUVChannelFilterNeedSize(int linesize, int width, int height, int channel_count);
void SGYUVChannelFilter(UInt8 * src, int linesize, int width, int height, UInt8 * dst, size_t dstsize, int channel_count);
