//
//  SGFFFrame.m
//  SGMediaKit
//
//  Created by Single on 06/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFFrame.h"
#import "SGFFTools.h"

@implementation SGFFFrame

@end


#pragma mark - Video Frame

@implementation SGFFVideoFrame

- (SGFFFrameType)type
{
    return SGFFFrameTypeVideo;
}

@end

@implementation SGFFAVYUVVideoFrame

- (SGFFFrameType)type
{
    return SGFFFrameTypeAVYUVVideo;
}

- (instancetype)initWithAVFrame:(AVFrame *)frame width:(int)width height:(int)height
{
    if (self = [super init]) {
        self->_width = width;
        self->_height = height;
        sg_ff_convert_AVFrame_to_YUV(frame->data[SGYUVChannelLuma],
                                     frame->linesize[SGYUVChannelLuma],
                                     width,
                                     height,
                                     &channel_pixels[SGYUVChannelLuma],
                                     &channel_lenghts[SGYUVChannelLuma]);
        sg_ff_convert_AVFrame_to_YUV(frame->data[SGYUVChannelChromaB],
                                     frame->linesize[SGYUVChannelChromaB],
                                     width / 2,
                                     height / 2,
                                     &channel_pixels[SGYUVChannelChromaB],
                                     &channel_lenghts[SGYUVChannelChromaB]);
        sg_ff_convert_AVFrame_to_YUV(frame->data[SGYUVChannelChromaR],
                                     frame->linesize[SGYUVChannelChromaR],
                                     width / 2,
                                     height / 2,
                                     &channel_pixels[SGYUVChannelChromaR],
                                     &channel_lenghts[SGYUVChannelChromaR]);
    }
    return self;
}

- (int)size
{
    return channel_lenghts[SGYUVChannelLuma] + channel_lenghts[SGYUVChannelChromaB] + channel_lenghts[SGYUVChannelChromaR];
}

- (void)dealloc
{
    free(channel_pixels[SGYUVChannelLuma]);
    free(channel_pixels[SGYUVChannelChromaB]);
    free(channel_pixels[SGYUVChannelChromaR]);
    
    channel_pixels[SGYUVChannelLuma] = nil;
    channel_pixels[SGYUVChannelChromaB] = nil;
    channel_pixels[SGYUVChannelChromaR] = nil;
}

@end

@implementation SGFFCVYUVVideoFrame

- (SGFFFrameType)type
{
    return SGFFFrameTypeCVYUVVideo;
}

- (instancetype)initWithAVPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (self = [super init]) {
        self->_pixelBuffer = pixelBuffer;
        if (self->_pixelBuffer) {
            CVPixelBufferRetain(self->_pixelBuffer);
        }
    }
    return self;
}

- (void)dealloc
{
    if (self->_pixelBuffer) {
        CVPixelBufferRelease(self->_pixelBuffer);
        self->_pixelBuffer = NULL;
    }
}

@end


#pragma mark - Audio Frame

@implementation SGFFAudioFrame

- (SGFFFrameType)type
{
    return SGFFFrameTypeAudio;
}

- (int)size
{
    return (int)self.samples.length;
}

@end


#pragma mark - Other Frame

@implementation SGFFSubtileFrame

- (SGFFFrameType)type
{
    return SGFFFrameTypeSubtitle;
}

@end

@implementation SGFFArtworkFrame

- (SGFFFrameType)type
{
    return SGFFFrameTypeArtwork;
}

@end
