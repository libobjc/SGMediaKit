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
@property (nonatomic, assign) int duration;

@property (nonatomic, strong) NSCondition * condition;
@property (nonatomic, strong) NSMutableArray <NSValue *> * packets;

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
    self.duration += packet.duration;
    [self.condition signal];
    [self.condition unlock];
}

- (AVPacket)getPacket
{
    [self.condition lock];
    while (!self.packets.firstObject) {
        [self.condition wait];
    }
    AVPacket packet;
    [self.packets.firstObject getValue:&packet];
    [self.packets removeObjectAtIndex:0];
    self.size -= packet.size;
    self.duration -= packet.duration;
    [self.condition unlock];
    return packet;
}

- (int)count
{
    return self.packets.count;
}

+ (int)maxCommonSize
{
    return 15 * 1024 * 1024;
}

+ (NSTimeInterval)sleepTimeInterval
{
    return 0.01;
}

@end
