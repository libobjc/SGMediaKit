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
}

- (SGDecoderType)decoderTypeForContentURL:(NSURL *)contentURL
{
    SGVideoFormat format = [self formatForContentURL:contentURL];
    switch (format) {
        case SGVideoFormatError:
            return SGDecoderTypeError;
        case SGVideoFormatUnknown:
            return self.unkonwnFormat;
        case SGVideoFormatMPEG4:
            return self.mpeg4Format;
        case SGVideoFormatFLV:
            return self.flvFormat;
        case SGVideoFormatM3U8:
            return self.m3u8Format;
        case SGVideoFormatRTMP:
            return self.rtmpFormat;
    }
}

@end
