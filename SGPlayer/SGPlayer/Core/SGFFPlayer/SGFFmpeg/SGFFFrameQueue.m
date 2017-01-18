//
//  SGFFFrameQueue.m
//  SGMediaKit
//
//  Created by Single on 18/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFFrameQueue.h"

@interface SGFFFrameQueue ()

@property (nonatomic, assign) int count;
@property (nonatomic, assign) int duration;

@property (nonatomic, strong) NSCondition * condition;
@property (nonatomic, strong) NSMutableArray <SGFFFrame *> * frames;

@end

@implementation SGFFFrameQueue

+ (instancetype)frameQueue
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
        self.frames = [NSMutableArray array];
        self.condition = [[NSCondition alloc] init];
    }
    return self;
}

- (void)putFrame:(SGFFFrame *)frame
{
    if (!frame) return;
    [self.condition lock];
    [self.frames addObject:frame];
    self.duration += frame.duration;
    [self.condition signal];
    [self.condition unlock];
}

- (SGFFFrame *)getFrame
{
    [self.condition lock];
    while (!self.frames.firstObject) {
        [self.condition wait];
    }
    SGFFFrame * frame = self.frames.firstObject;
    [self.frames removeObjectAtIndex:0];
    self.duration -= frame.duration;
    [self.condition unlock];
    return frame;
}

- (int)count
{
    return self.frames.count;
}

+ (int)commonMaxDuration
{
    return [self videoMaxDuration] + [self audioMaxDuration];
}

+ (int)videoMaxDuration
{
    return 2;
}

+ (int)audioMaxDuration
{
    return 4;
}

+ (NSTimeInterval)sleepTimeInterval
{
    return 0.01;
}

@end
