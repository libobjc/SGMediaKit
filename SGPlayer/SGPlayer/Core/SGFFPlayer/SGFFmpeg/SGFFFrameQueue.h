//
//  SGFFFrameQueue.h
//  SGMediaKit
//
//  Created by Single on 18/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFFrame.h"

@interface SGFFFrameQueue : NSObject

+ (instancetype)frameQueue;

+ (int)commonMaxDuration;
+ (int)videoMaxDuration;
+ (int)audioMaxDuration;

+ (NSTimeInterval)sleepTimeInterval;

@property (nonatomic, assign, readonly) int count;
@property (nonatomic, assign, readonly) int duration;

- (void)putFrame:(SGFFFrame *)frame;
- (SGFFFrame *)getFrame;

@end
