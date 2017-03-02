//
//  SGFFVideoFramePool.h
//  SGMediaKit
//
//  Created by Single on 2017/3/2.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFVideoFrame.h"

@interface SGFFVideoFramePool : NSObject

+ (instancetype)pool;

- (NSUInteger)count;
- (NSUInteger)unuseCount;
- (NSUInteger)usedCount;

- (SGFFAVYUVVideoFrame *)getUnuseFrame;

- (void)flush;

@end
