//
//  SGPlayerDecoder.m
//  SGMediaKit
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGPlayerDecoder.h"

@implementation SGPlayerDecoder

+ (instancetype)defaultDecoder
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
        self.unkonwnFormat = SGDecoderTypeFFmpeg;
        self.mpeg4Format = SGDecoderTypeAVPlayer;
        self.flvFormat = SGDecoderTypeFFmpeg;
        self.m3u8Format = SGDecoderTypeAVPlayer;
        self.rtmpFormat = SGDecoderTypeFFmpeg;
    }
    return self;
}

- (SGVideoFormat)formatForContentURL:(NSURL *)contentURL
{
    if (!contentURL) return SGVideoFormatError;
    return SGVideoFormatUnknown;
//    return SGVideoFormatMPEG4;
}

- (SGDecoderType)decoderTypeForContentURL:(NSURL *)contentURL
{
    SGVideoFormat format = [self formatForContentURL:contentURL];
    switch (format) {
        case SGVideoFormatError:
            return SGDecoderTypeError;
        case SGVideoFormatUnknown:
            return SGDecoderTypeFFmpeg;
        case SGVideoFormatMPEG4:
            return SGDecoderTypeAVPlayer;
        case SGVideoFormatFLV:
            return SGDecoderTypeFFmpeg;
        case SGVideoFormatM3U8:
            return SGDecoderTypeAVPlayer;
        case SGVideoFormatRTMP:
            return SGDecoderTypeFFmpeg;
    }
}

@end
