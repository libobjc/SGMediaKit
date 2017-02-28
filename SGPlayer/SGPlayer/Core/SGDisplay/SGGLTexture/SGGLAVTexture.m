//
//  SGGLAVTexture.m
//  SGMediaKit
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGGLAVTexture.h"
#import "SGPlayerMacro.h"
#import "SGPLFGLCVOpenGLTexture.h"

@interface SGGLAVTexture ()

@property (nonatomic, strong) SGPLFGLContext * context;

@property (nonatomic, assign) SGPLFGLCVOpenGLTextureRef lumaTexture;
@property (nonatomic, assign) SGPLFGLCVOpenGLTextureRef chromaTexture;
@property (nonatomic, assign) SGPLFGLCVOpenGLTextureCacheRef videoTextureCache;

@property (nonatomic, assign) CGFloat textureAspect;

@end

@implementation SGGLAVTexture

- (instancetype)initWithContext:(SGPLFGLContext *)context
{
    if (self = [super init]) {
        self.context = context;
        [self setupVideoCache];
    }
    return self;
}

- (void)setupVideoCache
{
    if (!self.videoTextureCache)
    {
        CVReturn result = SGPLFGLCVOpenGLTextureCacheCreate(self.context, &_videoTextureCache);
        if (result != noErr)
        {
            SGPlayerLog(@"create CVOpenGLTextureCacheCreate failure %d", result);
            return;
        }
    }
}

- (void)updateTextureWithPixelBuffer:(CVPixelBufferRef)pixelBuffer aspect:(CGFloat *)aspect needRelease:(BOOL)needRelease
{
    if (pixelBuffer == nil) {
        if (self.lumaTexture) {
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(SGPLFGLCVOpenGLTextureGetTarget(self.lumaTexture), SGPLFGLCVOpenGLTextureGetName(self.lumaTexture));
            * aspect = self.textureAspect;
        }
        if (self.chromaTexture) {
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(SGPLFGLCVOpenGLTextureGetTarget(self.chromaTexture), SGPLFGLCVOpenGLTextureGetName(self.chromaTexture));
            * aspect = self.textureAspect;
        }
        return;
    }
    
    CVReturn result;
    
    GLsizei textureWidth = (GLsizei)CVPixelBufferGetWidth(pixelBuffer);
    GLsizei textureHeight = (GLsizei)CVPixelBufferGetHeight(pixelBuffer);
    self.textureAspect = (textureWidth * 1.0) / (textureHeight * 1.0);
    * aspect = self.textureAspect;
    
    if (!self.videoTextureCache) {
        SGPlayerLog(@"no video texture cache");
        return;
    }
    
    [self cleanTextures];
    
    
    // Y-plane
    glActiveTexture(GL_TEXTURE0);
#if SGPLATFORM_TARGET_OS_MAC
    result = CVOpenGLTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.videoTextureCache, pixelBuffer, NULL, &_lumaTexture);
#elif SGPLATFORM_TARGET_OS_IPHONE
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
#endif
    if (result != kCVReturnSuccess) {
        SGPlayerLog(@"create CVOpenGLESTextureCacheCreateTextureFromImage failure 1 %d", result);
    }
    
    glBindTexture(SGPLFGLCVOpenGLTextureGetTarget(self.lumaTexture), SGPLFGLCVOpenGLTextureGetName(self.lumaTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // UV-plane.
    glActiveTexture(GL_TEXTURE1);
#if SGPLATFORM_TARGET_OS_MAC
    result = CVOpenGLTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.videoTextureCache, pixelBuffer, NULL, &_chromaTexture);
#elif SGPLATFORM_TARGET_OS_IPHONE
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
#endif
    if (result != kCVReturnSuccess) {
        SGPlayerLog(@"create CVOpenGLESTextureCacheCreateTextureFromImage failure 2 %d", result);
    }
    
    glBindTexture(SGPLFGLCVOpenGLTextureGetTarget(self.chromaTexture), SGPLFGLCVOpenGLTextureGetName(self.chromaTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    if (needRelease) {
        CVPixelBufferRelease(pixelBuffer);
    }
    
    _hasTexture = YES;
}

- (void)dealloc
{
    SGPlayerLog(@"SGAVGLTexture release");
    _hasTexture = NO;
    [self clearVideoCache];
    [self cleanTextures];
}

- (void)clearVideoCache
{
    if (_videoTextureCache) {
        CFRelease(_videoTextureCache);
        self.videoTextureCache = nil;
    }
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
    
    self.textureAspect = 16.0 / 9.0;
    SGPLFGLCVOpenGLTextureCacheFlush(_videoTextureCache, 0);
}

@end
