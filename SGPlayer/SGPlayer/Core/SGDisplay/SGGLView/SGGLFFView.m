//
//  SGGLFFView.m
//  SGMediaKit
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGGLFFView.h"
#import "SGGLFFProgram.h"

@interface SGGLFFView ()

{
    GLuint _textures[3];
}

@property (nonatomic, strong) SGGLFFProgram * program;
@property (atomic, strong) SGFFVideoFrame * videoFrame;

@end

@implementation SGGLFFView

- (void)renderFrame:(SGFFVideoFrame *)frame
{
    self.videoFrame = frame;
    [self display];
}

- (BOOL)updateTexture
{
    if (!self.videoFrame) return NO;
    
//    assert(self.videoFrame.luma.length == self.videoFrame.width * self.videoFrame.height);
//    assert(self.videoFrame.chromaB.length == (self.videoFrame.width * self.videoFrame.height) / 4);
//    assert(self.videoFrame.chromaR.length == (self.videoFrame.width * self.videoFrame.height) / 4);
    
    const NSUInteger frameWidth = self.videoFrame.width;
    const NSUInteger frameHeight = self.videoFrame.height;
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    const UInt8 * pixels[3] = {
        self.videoFrame.luma.bytes,
        self.videoFrame.chromaB.bytes,
        self.videoFrame.chromaR.bytes
    };
    const NSUInteger widths[3]  = {
        frameWidth,
        frameWidth / 2,
        frameWidth / 2
    };
    const NSUInteger heights[3] = {
        frameHeight,
        frameHeight / 2,
        frameHeight / 2
    };
    
    for (int i = 0; i < 3; i++) {
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, _textures[i]);
        glTexImage2D(GL_TEXTURE_2D,
                     0,
                     GL_LUMINANCE,
                     widths[i],
                     heights[i],
                     0,
                     GL_LUMINANCE,
                     GL_UNSIGNED_BYTE,
                     pixels[i]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    
    return YES;
}

- (void)setupProgram
{
    self.program = [SGGLFFProgram program];
}

- (void)setupSubClass
{
    glGenTextures(3, _textures);
}

- (void)dealloc
{
    glDeleteTextures(3, _textures);
}

@end
