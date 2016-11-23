//
//  SGAVGLTexture.m
//  SGPlayer
//
//  Created by Single on 16/7/26.
//  Copyright © 2016年 single. All rights reserved.
//

#import "SGAVGLTexture.h"
#import "SGPlayerMacro.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface SGAVGLTexture ()

@property (nonatomic, strong) EAGLContext * context;
@property (nonatomic, assign) CVOpenGLESTextureRef lumaTexture;
@property (nonatomic, assign) CVOpenGLESTextureRef chromaTexture;
@property (nonatomic, assign) CVOpenGLESTextureCacheRef videoTextureCache;

@end

@implementation SGAVGLTexture

- (instancetype)initWithContext:(EAGLContext *)context
{
    if (self = [super init]) {
        self.context = context;
        [self setupVideoCache];
    }
    return self;
}

- (void)setupVideoCache
{
    if (!self.videoTextureCache) {
        CVReturn result = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.context, NULL, &_videoTextureCache);
        if (result != noErr) {
            SGLog(@"create CVOpenGLESTextureCacheCreate failure %d", result);
            return;
        }
    }
}

- (void)updateTextureWithPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (pixelBuffer == nil) return;
    
    CVReturn result;
    
    GLsizei textureWidth = (GLsizei)CVPixelBufferGetWidth(pixelBuffer);
    GLsizei textureHeight = (GLsizei)CVPixelBufferGetHeight(pixelBuffer);
    
    if (!self.videoTextureCache) {
        SGLog(@"no video texture cache");
        return;
    }
    
    [self cleanTextures];
    
    // Y-plane
    glActiveTexture(GL_TEXTURE0);
    result = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                          self.videoTextureCache,
                                                          pixelBuffer,
                                                          NULL,
                                                          GL_TEXTURE_2D,
                                                          GL_RED_EXT,
                                                          textureWidth,
                                                          textureHeight,
                                                          GL_RED_EXT,
                                                          GL_UNSIGNED_BYTE,
                                                          0,
                                                          &_lumaTexture);
    if (result) {
        SGLog(@"create CVOpenGLESTextureCacheCreateTextureFromImage failure 1 %d", result);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(self.lumaTexture), CVOpenGLESTextureGetName(self.lumaTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // UV-plane.
    glActiveTexture(GL_TEXTURE1);
    result = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                          self.videoTextureCache,
                                                          pixelBuffer,
                                                          NULL,
                                                          GL_TEXTURE_2D,
                                                          GL_RG_EXT,
                                                          textureWidth/2,
                                                          textureHeight/2,
                                                          GL_RG_EXT,
                                                          GL_UNSIGNED_BYTE,
                                                          1,
                                                          &_chromaTexture);
    if (result) {
        SGLog(@"create CVOpenGLESTextureCacheCreateTextureFromImage failure 2 %d", result);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(self.chromaTexture), CVOpenGLESTextureGetName(self.chromaTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    CFRelease(pixelBuffer);
    
    _hasTexture = YES;
}

- (void)dealloc
{
    SGLog(@"SGAVGLTexture release");
    _hasTexture = NO;
    [self clearVideoCache];
    [self cleanTextures];
}

- (void)clearVideoCache
{
    CFRelease(_videoTextureCache);
    self.videoTextureCache = nil;
}

- (void)cleanTextures
{
    if (self.lumaTexture) {
        CFRelease(_lumaTexture);
        self.lumaTexture = NULL;
    }
    
    if (self.chromaTexture) {
        CFRelease(_chromaTexture);
        self.chromaTexture = NULL;
    }
    
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

@end
