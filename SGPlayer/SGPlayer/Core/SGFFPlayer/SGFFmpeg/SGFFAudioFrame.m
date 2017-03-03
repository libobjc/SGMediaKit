//
//  SGFFAudioFrame.m
//  SGMediaKit
//
//  Created by Single on 2017/2/17.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGFFAudioFrame.h"

@implementation SGFFAudioFrame

+ (instancetype)audioFrame
{
    static int count = 0;
    count++;
    NSLog(@"音频帧 创建 : %d", count);
    
    return [[self alloc] init];
}

- (SGFFFrameType)type
{
    return SGFFFrameTypeAudio;
}

- (int)size
{
    return (int)self.samples.length;
}

- (void)startPlaying
{
    if ([self.delegate respondsToSelector:@selector(audioFrameDidStartPlaying:)]) {
        [self.delegate audioFrameDidStartPlaying:self];
    }
}

- (void)stopPlaying
{
    if ([self.delegate respondsToSelector:@selector(audioFrameDidStopPlaying:)]) {
        [self.delegate audioFrameDidStopPlaying:self];
    }
}

- (void)cancel
{
    if ([self.delegate respondsToSelector:@selector(audioFrameDidCancel:)]) {
        [self.delegate audioFrameDidCancel:self];
    }
}

- (void)dealloc
{
    static int count = 0;
    count++;
    NSLog(@"音频帧 释放 : %d", count);
}

@end
