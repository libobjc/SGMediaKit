//
//  SGFFPacketQueue.m
//  SGMediaKit
//
//  Created by Single on 18/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFPacketQueue.h"

@interface SGFFPacketQueue ()

@property (nonatomic, assign) int size;
@property (atomic, assign) NSTimeInterval duration;

@property (nonatomic, strong) NSCondition * condition;
@property (nonatomic, strong) NSMutableArray <NSValue *> * packets;

@property (nonatomic, assign) BOOL destoryToken;

@end

@implementation SGFFPacketQueue

+ (instancetype)packetQueue
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
        self.packets = [NSMutableArray array];
        self.condition = [[NSCondition alloc] init];
    }
    return self;
}

- (void)putPacket:(AVPacket)packet
{
    [self.condition lock];
    NSValue * value = [NSValue value:&packet withObjCType:@encode(AVPacket)];
    [self.packets addObject:value];
    self.size += packet.size;
//    self.duration += packet.duration;
    [self.condition signal];
    [self.condition unlock];
}

- (AVPacket)getPacket
{
    [self.condition lock];
    AVPacket packet;
    while (!self.packets.firstObject) {
        if (self.destoryToken) {
            [self.condition unlock];
            return packet;
        }
        [self.condition wait];
    }
    [self.packets.firstObject getValue:&packet];
    [self.packets removeObjectAtIndex:0];
    self.size -= packet.size;
    if (self.size < 0) {
        self.size = 0;
    }
//    self.duration -= packet.duration;
    if (self.duration < 0) {
        self.duration = 0;
    }
    [self.condition unlock];
    return packet;
}

- (void)flush
{
    [self.condition lock];
    for (NSValue * value in self.packets) {
        AVPacket packet;
        [value getValue:&packet];
        av_packet_unref(&packet);
    }
    [self.packets removeAllObjects];
    self.size = 0;
    self.duration = 0;
    [self.condition unlock];
}

- (void)destroy
{
    [self flush];
    [self.condition lock];
    self.destoryToken = YES;
    [self.condition broadcast];
    [self.condition unlock];
}

- (int)count
{
    return self.packets.count;
}

+ (int)maxCommonSize
{
    return 15 * 1024 * 1024;
}

+ (NSTimeInterval)sleepTimeIntervalForFull
{
    return 0.01;
}

+ (NSTimeInterval)sleepTimeIntervalForFullAndPaused
{
    return 0.5;
}

@end
