//
//  SGAVGLProgram.h
//  SGPlayer
//
//  Created by Single on 16/7/25.
//  Copyright © 2016年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface SGAVGLProgram : NSObject

+ (instancetype)program;
- (void)use;
- (void)prepareVariable;

@property (nonatomic, assign, readonly) GLuint pPosition;
@property (nonatomic, assign, readonly) GLuint pTextureCoord;
@property (nonatomic, assign, readonly) GLuint pMvpMatrix;

@end
