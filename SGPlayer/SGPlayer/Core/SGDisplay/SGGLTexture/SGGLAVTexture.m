//
//  SGGLAVTexture.m
//  SGMediaKit
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGGLAVTexture.h"
#import "SGPlayerMacro.h"

#if SGPLATFORM_TARGET_OS_MAC

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

@interface SGGLAVTexture ()

{
    GLuint _texture_y_id;
    GLuint _texture_uv_id;
}

@property (nonatomic, assign) CGFloat textureAspect;
@property (nonatomic, assign) BOOL didBindTexture;

@end

@implementation SGGLAVTexture

- (instancetype)initWithContext:(SGPLFGLContext *)context
{
    if (self = [super init]) {
        glGenTextures(1, &_texture_y_id);
        glGenTextures(1, &_texture_uv_id);
    }
    return self;
}

- (void)updateTextureWithPixelBuffer:(CVPixelBufferRef)pixelBuffer aspect:(CGFloat *)aspect needRelease:(BOOL)needRelease
{
    if (pixelBuffer == nil) {
        if (self.didBindTexture) {
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, _texture_y_id);
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(GL_TEXTURE_2D, _texture_uv_id);
            * aspect = self.textureAspect;
        }
        return;
    }
    
    GLsizei textureWidth = (GLsizei)CVPixelBufferGetWidth(pixelBuffer);
    GLsizei textureHeight = (GLsizei)CVPixelBufferGetHeight(pixelBuffer);
    self.textureAspect = (textureWidth * 1.0) / (textureHeight * 1.0);
    * aspect = self.textureAspect;
    
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    
    void * data_y = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    size_t linesize_y = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    size_t width_y = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    size_t height_y = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    
    void * data_uv = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    size_t linesize_uv = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    size_t width_uv = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
    size_t height_uv = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
    
    void * real_y;
    convert_Y(data_y, linesize_y, width_y, height_y, &real_y);
    void * real_uv;
    convert_UV(data_uv, linesize_uv, width_uv, height_uv, &real_uv);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture_y_id);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width_y, height_y, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, real_y);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glActiveTexture(GL_TEXTURE0);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _texture_uv_id);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE_ALPHA, width_uv, height_uv, 0, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, real_uv);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glActiveTexture(GL_TEXTURE1);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    
    if (needRelease) {
        CVPixelBufferRelease(pixelBuffer);
    }
    
    free(real_y);
    free(real_uv);
    
    _hasTexture = YES;
    self.didBindTexture = YES;
}

void convert_Y(UInt8 * src, int linesize, int width, int height, UInt8 ** dst)
{
    width = MIN(linesize, width);
    * dst = malloc(width * height);
    UInt8 * temp = * dst;
    memset(* dst, 0, width * height);
    for (int i = 0; i < height; i++) {
        memcpy(temp, src, width);
        temp += width;
        src += linesize;
    }
}

void convert_UV(UInt8 * src, int linesize, int width, int height, UInt8 ** dst)
{
    width = MIN(linesize, width);
    * dst = malloc(width * height * 2);
    UInt8 * temp = * dst;
    memset(* dst, 0, width * height * 2);
    for (int i = 0; i < height; i++) {
        memcpy(temp, src, width * 2);
        temp += (width * 2);
        src += linesize;
    }
}

- (void)cleanTextures
{
    if (_texture_y_id) {
        glDeleteTextures(1, &_texture_y_id);
        _texture_y_id = 0;
    }
    if (_texture_uv_id) {
        glDeleteTextures(1, &_texture_uv_id);
        _texture_uv_id = 0;
    }
}

- (void)dealloc
{
    [self cleanTextures];
    _hasTexture = NO;
    SGPlayerLog(@"SGGLAVTexture release");
}

@end

#elif SGPLATFORM_TARGET_OS_IPHONE

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface SGGLAVTexture ()

@property (nonatomic, strong) SGPLFGLContext * context;

@property (nonatomic, assign) CVOpenGLESTextureRef lumaTexture;
@property (nonatomic, assign) CVOpenGLESTextureRef chromaTexture;
@property (nonatomic, assign) CVOpenGLESTextureCacheRef videoTextureCache;

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
    if (!self.videoTextureCache) {
        CVReturn result = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.context, NULL, &_videoTextureCache);
        if (result != noErr) {
            SGPlayerLog(@"create CVOpenGLESTextureCacheCreate failure %d", result);
            return;
        }
    }
}

- (void)updateTextureWithPixelBuffer:(CVPixelBufferRef)pixelBuffer aspect:(CGFloat *)aspect needRelease:(BOOL)needRelease
{
    if (pixelBuffer == nil) {
        if (self.lumaTexture) {
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(CVOpenGLESTextureGetTarget(self.lumaTexture), CVOpenGLESTextureGetName(self.lumaTexture));
            * aspect = self.textureAspect;
        }
        if (self.chromaTexture) {
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(CVOpenGLESTextureGetTarget(self.chromaTexture), CVOpenGLESTextureGetName(self.chromaTexture));
            * aspect = self.textureAspect;
        }
        return;
    }
    
    GLsizei textureWidth = (GLsizei)CVPixelBufferGetWidth(pixelBuffer);
    GLsizei textureHeight = (GLsizei)CVPixelBufferGetHeight(pixelBuffer);
    self.textureAspect = (textureWidth * 1.0) / (textureHeight * 1.0);
    * aspect = self.textureAspect;
    
    if (!self.videoTextureCache) {
        SGPlayerLog(@"no video texture cache");
        return;
    }
    
    [self cleanTextures];
    
    CVReturn result;
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
    
    if (result == kCVReturnSuccess) {
        glBindTexture(CVOpenGLESTextureGetTarget(self.lumaTexture), CVOpenGLESTextureGetName(self.lumaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    } else {
        SGPlayerLog(@"create CVOpenGLESTextureCacheCreateTextureFromImage failure 1 %d", result);
    }
    
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
    
    if (result == kCVReturnSuccess) {
        glBindTexture(CVOpenGLESTextureGetTarget(self.chromaTexture), CVOpenGLESTextureGetName(self.chromaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    } else {
        SGPlayerLog(@"create CVOpenGLESTextureCacheCreateTextureFromImage failure 2 %d", result);
    }
    
    if (needRelease) {
        CVPixelBufferRelease(pixelBuffer);
    }
    
    _hasTexture = YES;
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
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

- (void)dealloc
{
    [self clearVideoCache];
    [self cleanTextures];
    _hasTexture = NO;
    SGPlayerLog(@"SGAVGLTexture release");
}

@end

#endif
