//
//  SGGLProgram.h
//  SGMediaKit
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface SGGLProgram : NSObject

+ (SGGLProgram *)avplayerProgram;
+ (SGGLProgram *)ffmpegProgram;

@property (nonatomic, assign, readonly) GLint position_location;
@property (nonatomic, assign, readonly) GLint texture_coord_location;
@property (nonatomic, assign, readonly) GLint matrix_location;

- (void)setMatrix:(GLKMatrix4)matrix;
- (void)prepare;
- (void)use;

@end
