//
//  SGAVGLSensors.h
//  SGPlayer
//
//  Created by Single on 16/8/12.
//  Copyright © 2016年 single. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface SGAVGLSensors : NSObject

@property (nonatomic, assign, readonly) GLKMatrix4 modelView;
@property (nonatomic, assign, readonly, getter=isReady) BOOL ready;

- (void)start;
- (void)stop;

@end
