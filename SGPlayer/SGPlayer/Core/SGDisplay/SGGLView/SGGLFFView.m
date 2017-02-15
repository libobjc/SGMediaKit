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

- (void)renderFrame:(__kindof SGFFVideoFrame *)frame
{
    self.videoFrame = frame;
    [self displayAsyncOnMainThread];
}

- (BOOL)updateTextureAspect:(CGFloat *)aspect
{
    if (!self.videoFrame) return NO;
    
//    assert(self.videoFrame.luma.length == self.videoFrame.width * self.videoFrame.height);
//    assert(self.videoFrame.chromaB.length == (self.videoFrame.width * self.videoFrame.height) / 4);
//    assert(self.videoFrame.chromaR.length == (self.videoFrame.width * self.videoFrame.height) / 4);
    
    if ([self.videoFrame isKindOfClass:[SGFFAVYUVVideoFrame class]])
    {
        SGFFAVYUVVideoFrame * frame = (SGFFAVYUVVideoFrame *)self.videoFrame;
        
        const int frameWidth = frame.width;
        const int frameHeight = frame.height;
        * aspect = (frameWidth * 1.0) / (frameHeight * 1.0);
        
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        
        const int widths[3]  = {
            frameWidth,
            frameWidth / 2,
            frameWidth / 2
        };
        const int heights[3] = {
            frameHeight,
            frameHeight / 2,
            frameHeight / 2
        };
        
        for (SGYUVChannel channel = SGYUVChannelLuma; channel < SGYUVChannelCount; channel++)
        {
            glActiveTexture(GL_TEXTURE0 + channel);
            glBindTexture(GL_TEXTURE_2D, _textures[channel]);
            glTexImage2D(GL_TEXTURE_2D,
                         0,
                         GL_LUMINANCE,
                         widths[channel],
                         heights[channel],
                         0,
                         GL_LUMINANCE,
                         GL_UNSIGNED_BYTE,
                         frame->channel_pixels[channel]);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        }
    }
    
    return YES;
}

- (void)cleanTexture
{
    self.videoFrame = nil;
}

- (void)setupProgram
{
    self.program = [SGGLFFProgram program];
}

- (void)setupSubClass
{
    glGenTextures(3, _textures);
}

- (void)willDealloc
{
    glDeleteTextures(3, _textures);
}

@end
