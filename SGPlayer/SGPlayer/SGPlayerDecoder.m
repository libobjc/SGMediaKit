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
        self.rtspFormat = SGDecoderTypeFFmpeg;
    }
    return self;
}

- (SGVideoFormat)formatForContentURL:(NSURL *)contentURL
{
    if (!contentURL) return SGVideoFormatError;
    NSString * path;
    if (contentURL.isFileURL) {
        path = contentURL.path;
    } else {
        path = contentURL.absoluteString;
    }
    if ([path hasPrefix:@"rtmp:"]) {
        return SGVideoFormatRTMP;
    } else if ([path hasPrefix:@"rtsp:"]) {
        return SGVideoFormatRTSP;
    } else if ([path containsString:@".flv"]) {
        return SGVideoFormatFLV;
    } else if ([path containsString:@".mp4"]) {
        return SGVideoFormatMPEG4;
    } else if ([path containsString:@".m3u8"]) {
        return SGVideoFormatM3U8;
    }
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
        case SGVideoFormatRTSP:
            return self.rtspFormat;
    }
}

@end
