//
//  SGPLFGLCVTexture.m
//  SGMediaKit
//
//  Created by Single on 2017/2/28.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFGLCVOpenGLTexture.h"

#if SGPLATFORM_TARGET_OS_MAC

CV_EXPORT CVReturn SGPLFGLCVOpenGLTextureCacheCreate(SGPLFGLContext * context, SGPLFGLCVOpenGLTextureCacheRef * cacheRef)
{
    NSOpenGLPixelFormat * pixelFormat = SGPLFGLContextGetPixelFormat(context);
    CVReturn result = CVOpenGLTextureCacheCreate(
                                                 kCFAllocatorDefault,
                                                 NULL,
                                                 (__bridge void *)context,
                                                 [pixelFormat CGLPixelFormatObj],
                                                 NULL,
                                                 cacheRef
                                                 );
    return result;
}

CV_EXPORT GLenum SGPLFGLCVOpenGLTextureGetTarget(SGPLFGLCVOpenGLTextureRef image)
{
    return CVOpenGLTextureGetTarget(image);
}

CV_EXPORT GLenum SGPLFGLCVOpenGLTextureGetName(SGPLFGLCVOpenGLTextureRef image)
{
    return CVOpenGLTextureGetName(image);
}

CV_EXPORT void SGPLFGLCVOpenGLTextureCacheFlush(SGPLFGLCVOpenGLTextureCacheRef textureCache, CVOptionFlags options)
{
    CVOpenGLTextureCacheFlush(textureCache, options);
}

#elif SGPLATFORM_TARGET_OS_IPHONE

CV_EXPORT CVReturn SGPLFGLCVOpenGLTextureCacheCreate(SGPLFGLContext * context, SGPLFGLCVOpenGLTextureCacheRef * cacheRef)
{
    CVReturn result = CVOpenGLESTextureCacheCreate(
                                                   kCFAllocatorDefault,
                                                   NULL,
                                                   context,
                                                   NULL,
                                                   cacheRef
                                                   );
    return result;
}

CV_EXPORT GLenum SGPLFGLCVOpenGLTextureGetTarget(SGPLFGLCVOpenGLTextureRef image)
{
    return CVOpenGLESTextureGetTarget(image);
}

CV_EXPORT GLenum SGPLFGLCVOpenGLTextureGetName(SGPLFGLCVOpenGLTextureRef image)
{
    return CVOpenGLESTextureGetName(image);
}

CV_EXPORT void SGPLFGLCVOpenGLTextureCacheFlush(SGPLFGLCVOpenGLTextureCacheRef textureCache, CVOptionFlags options)
{
    CVOpenGLESTextureCacheFlush(textureCache, options);
}

#endif
