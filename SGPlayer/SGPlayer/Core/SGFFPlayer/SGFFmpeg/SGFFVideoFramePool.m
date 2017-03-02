//
//  SGFFVideoFramePool.m
//  SGMediaKit
//
//  Created by Single on 2017/3/2.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGFFVideoFramePool.h"
#import "SGPlayerMacro.h"

@interface SGFFVideoFramePool () <SGFFVideoFrameDelegate>

@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, strong) SGFFAVYUVVideoFrame * drawingFrame;
@property (nonatomic, strong) NSMutableSet <SGFFAVYUVVideoFrame *> * unuseFrames;
@property (nonatomic, strong) NSMutableSet <SGFFAVYUVVideoFrame *> * usedFrames;

@end

@implementation SGFFVideoFramePool

+ (instancetype)pool
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
        self.lock = [[NSLock alloc] init];
        self.unuseFrames = [NSMutableSet setWithCapacity:50];
        self.usedFrames = [NSMutableSet setWithCapacity:50];
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

- (SGFFAVYUVVideoFrame *)getUnuseFrame
{
    [self.lock lock];
    SGFFAVYUVVideoFrame * videoFrame;
    if (self.unuseFrames.count > 0) {
        videoFrame = [self.unuseFrames anyObject];
        [self.unuseFrames removeObject:videoFrame];
        [self.usedFrames addObject:videoFrame];
        
    } else {
        videoFrame = [SGFFAVYUVVideoFrame videoFrame];
        videoFrame.delegate = self;
        [self.usedFrames  addObject:videoFrame];
    }
    [self.lock unlock];
    return videoFrame;
}

- (void)setFrameUnuse:(SGFFAVYUVVideoFrame *)frame
{
    if (!frame) return;
    if (![frame isKindOfClass:[SGFFAVYUVVideoFrame class]]) return;
    [self.lock lock];
    SGFFAVYUVVideoFrame * videoFrame = frame;
    [self.usedFrames removeObject:videoFrame];
    [self.unuseFrames addObject:videoFrame];
    [self.lock unlock];
}

- (void)setFrameStartDrawing:(SGFFAVYUVVideoFrame *)frame
{
    if (!frame) return;
    if (![frame isKindOfClass:[SGFFAVYUVVideoFrame class]]) return;
    [self.lock lock];
    if (self.drawingFrame) {
        [self.unuseFrames addObject:self.drawingFrame];
    }
    self.drawingFrame = frame;
    [self.usedFrames removeObject:self.drawingFrame];
    [self.lock unlock];
}

- (void)setFrameStopDrawing:(SGFFAVYUVVideoFrame *)frame
{
    if (!frame) return;
    if (![frame isKindOfClass:[SGFFAVYUVVideoFrame class]]) return;
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
    [self.usedFrames enumerateObjectsUsingBlock:^(SGFFAVYUVVideoFrame * _Nonnull obj, BOOL * _Nonnull stop) {
        [self.unuseFrames addObject:obj];
    }];
    [self.usedFrames removeAllObjects];
    [self.lock unlock];
}

#pragma mark - SGFFAVVideoFrameDelegate

- (void)videoFrameDidStartDrawing:(SGFFVideoFrame *)videoFrame
{
    [self setFrameStartDrawing:videoFrame];
}

- (void)videoFrameDidStopDrawing:(SGFFVideoFrame *)videoFrame
{
    [self setFrameStopDrawing:videoFrame];
}

- (void)dealloc
{
    SGPlayerLog(@"SGFFVideoFramePool release");
}

@end
