//
//  SGFFPacketQueue.h
//  SGMediaKit
//
//  Created by Single on 18/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "avformat.h"

@interface SGFFPacketQueue : NSObject

+ (instancetype)packetQueue;

+ (int)commonMaxSize NS_UNAVAILABLE;
+ (int)videoMaxSize NS_UNAVAILABLE;
+ (int)audioMaxSize NS_UNAVAILABLE;

+ (int)commonMaxDuration;
+ (int)videoMaxDuration;
+ (int)audioMaxDuration;

+ (NSTimeInterval)sleepTimeInterval;

@property (nonatomic, assign, readonly) int count;
@property (nonatomic, assign, readonly) int size;
@property (nonatomic, assign, readonly) int duration;

- (void)putPacket:(AVPacket)packet;
- (AVPacket)getPacket;

@end
