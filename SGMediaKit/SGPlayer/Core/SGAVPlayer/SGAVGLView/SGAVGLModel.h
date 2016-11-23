//
//  SGAVGLModel.h
//  SGPlayer
//
//  Created by Single on 2016/10/9.
//  Copyright © 2016年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface SGAVGLModel : NSObject

+ (instancetype)model;
- (void)bindBufferVertexPointer:(GLuint)vertexPointer textureCoordPointer:(GLuint)textureCoordPointer;
- (int)indexCount;

@end
