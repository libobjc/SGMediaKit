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

@implementation SGFFVideoFrame

- (instancetype)initWithAVFrame:(AVFrame *)frame width:(int)width height:(int)height
{
    if (self = [super init]) {
        _width = width;
        _height = height;
        sg_ff_convert_AVFrame_to_YUV(frame->data[0], frame->linesize[0], width, height, &luma, &lumaLenght);
        sg_ff_convert_AVFrame_to_YUV(frame->data[1], frame->linesize[1], width / 2, height / 2, &chromaB, &chromaBLenght);
        sg_ff_convert_AVFrame_to_YUV(frame->data[2], frame->linesize[2], width / 2, height / 2, &chromaR, &chromaRLenght);
    }
    return self;
}

- (SGFFFrameType)type
{
    return SGFFFrameTypeVideo;
}

- (void)dealloc
{
    free(luma);
    free(chromaB);
    free(chromaR);
    
    luma = nil;
    chromaB = nil;
    chromaR = nil;
}

@end

@implementation SGFFAudioFrame

- (SGFFFrameType)type
{
    return SGFFFrameTypeAudio;
}

@end

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
