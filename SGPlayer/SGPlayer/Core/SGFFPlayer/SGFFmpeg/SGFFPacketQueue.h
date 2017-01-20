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

+ (int)maxCommonSize;

+ (NSTimeInterval)sleepTimeIntervalForFull;
+ (NSTimeInterval)sleepTimeIntervalForFullAndPaused;

@property (nonatomic, assign, readonly) int count;
@property (nonatomic, assign, readonly) int size;
@property (nonatomic, assign, readonly) int duration;

- (void)putPacket:(AVPacket)packet;
- (AVPacket)getPacket;

- (void)flush;
- (void)destroy;

@end
