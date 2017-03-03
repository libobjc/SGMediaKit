//
//  SGFFAudioFramePool.h
//  SGMediaKit
//
//  Created by Single on 2017/3/3.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFAudioFrame.h"

@interface SGFFAudioFramePool : NSObject

+ (instancetype)pool;

- (NSUInteger)count;
- (NSUInteger)unuseCount;
- (NSUInteger)usedCount;

- (SGFFAudioFrame *)getUnuseFrame;

- (void)flush;

@end
