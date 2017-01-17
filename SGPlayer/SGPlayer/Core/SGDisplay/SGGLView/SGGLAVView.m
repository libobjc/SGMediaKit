//
//  SGGLAVView.m
//  SGMediaKit
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGGLAVView.h"
#import "SGAVPlayer.h"
#import "SGGLAVProgram.h"
#import "SGGLAVTexture.h"

@interface SGGLAVView ()

@property (nonatomic, strong) CADisplayLink * displayLink;
@property (nonatomic, strong) SGGLAVProgram * program;
@property (nonatomic, strong) SGGLAVTexture * texture;

@end

@implementation SGGLAVView

- (BOOL)updateTexture
{
    CVPixelBufferRef pixelBuffer = [self.displayView.sgavplayer pixelBufferAtCurrentTime];
    if (!pixelBuffer && !self.texture.hasTexture) return NO;
    
    [self.texture updateTextureWithPixelBuffer:pixelBuffer];
    return YES;
}

- (void)setupProgram
{
    self.program = [SGGLAVProgram program];
}

- (void)setupSubClass
{
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkAction)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.displayLink.paused = NO;
}

- (void)displayLinkAction
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        [self display];
    }
}

- (void)setPaused:(BOOL)paused
{
    self.displayLink.paused = paused;
}

- (BOOL)paused
{
    return self.displayLink.paused;
}

- (SGGLAVTexture *)texture
{
    if (!_texture) {
        _texture = [[SGGLAVTexture alloc] initWithContext:self.context];
    }
    return _texture;
}

- (void)invalidate
{
    [self.displayLink invalidate];
}

@end
