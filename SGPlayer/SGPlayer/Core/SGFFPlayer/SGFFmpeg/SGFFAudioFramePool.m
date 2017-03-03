//
//  SGFFAudioFramePool.m
//  SGMediaKit
//
//  Created by Single on 2017/3/3.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGFFAudioFramePool.h"
#import "SGPlayerMacro.h"

@interface SGFFAudioFramePool () <SGFFAudioFrameDelegate>

@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, strong) SGFFAudioFrame * drawingFrame;
@property (nonatomic, strong) NSMutableSet <SGFFAudioFrame *> * unuseFrames;
@property (nonatomic, strong) NSMutableSet <SGFFAudioFrame *> * usedFrames;

@end

@implementation SGFFAudioFramePool

+ (instancetype)pool
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
        self.lock = [[NSLock alloc] init];
        self.unuseFrames = [NSMutableSet setWithCapacity:500];
        self.usedFrames = [NSMutableSet setWithCapacity:500];
    }
    return self;
}

- (NSUInteger)count
{
    return [self unuseCount] + [self usedCount] + (self.drawingFrame ? 1 : 0);
}

- (NSUInteger)unuseCount
{
    return self.unuseFrames.count;
}

- (NSUInteger)usedCount
{
    return self.usedFrames.count;
}

- (SGFFAudioFrame *)getUnuseFrame
{
    [self.lock lock];
    SGFFAudioFrame * audioFrame;
    if (self.unuseFrames.count > 0) {
        audioFrame = [self.unuseFrames anyObject];
        [self.unuseFrames removeObject:audioFrame];
        [self.usedFrames addObject:audioFrame];
        
    } else {
        audioFrame = [SGFFAudioFrame audioFrame];
        audioFrame.delegate = self;
        [self.usedFrames  addObject:audioFrame];
    }
    [self.lock unlock];
    return audioFrame;
}

- (void)setFrameUnuse:(SGFFAudioFrame *)frame
{
    if (!frame) return;
    if (![frame isKindOfClass:[SGFFAudioFrame class]]) return;
    [self.lock lock];
    SGFFAudioFrame * videoFrame = frame;
    [self.usedFrames removeObject:videoFrame];
    [self.unuseFrames addObject:videoFrame];
    [self.lock unlock];
}

- (void)setFramesUnuse:(NSArray <SGFFAudioFrame *> *)frames
{
    if (frames.count <= 0) return;
    [self.lock lock];
    for (SGFFAudioFrame * obj in frames) {
        if (![obj isKindOfClass:[SGFFAudioFrame class]]) continue;
        [self.usedFrames removeObject:obj];
        [self.unuseFrames addObject:obj];
    }
    [self.lock unlock];
}

- (void)setFrameStartDrawing:(SGFFAudioFrame *)frame
{
    if (!frame) return;
    if (![frame isKindOfClass:[SGFFAudioFrame class]]) return;
    [self.lock lock];
    if (self.drawingFrame) {
        [self.unuseFrames addObject:self.drawingFrame];
    }
    self.drawingFrame = frame;
    [self.usedFrames removeObject:self.drawingFrame];
    [self.lock unlock];
}

- (void)setFrameStopDrawing:(SGFFAudioFrame *)frame
{
    if (!frame) return;
    if (![frame isKindOfClass:[SGFFAudioFrame class]]) return;
    [self.lock lock];
    if (self.drawingFrame == frame) {
        [self.unuseFrames addObject:self.drawingFrame];
        self.drawingFrame = nil;
    }
    [self.lock unlock];
}

- (void)flush
{
    [self.lock lock];
    [self.usedFrames enumerateObjectsUsingBlock:^(SGFFAudioFrame * _Nonnull obj, BOOL * _Nonnull stop) {
        [self.unuseFrames addObject:obj];
    }];
    [self.usedFrames removeAllObjects];
    [self.lock unlock];
}

#pragma mark - SGFFAudioFrameDelegate

- (void)audioFrameDidStartPlaying:(SGFFAudioFrame *)audioFrame
{
    [self setFrameStartDrawing:audioFrame];
}

- (void)audioFrameDidStopPlaying:(SGFFAudioFrame *)audioFrame
{
    [self setFrameStopDrawing:audioFrame];
}

- (void)audioFrameDidCancel:(SGFFAudioFrame *)audioFrame
{
    [self setFrameUnuse:audioFrame];
}

- (void)dealloc
{
    SGPlayerLog(@"SGFFAudioFramePool release");
}

@end
