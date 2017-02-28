//
//  SGPLFGLCVTexture.h
//  SGMediaKit
//
//  Created by Single on 2017/2/28.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFMacro.h"
#import <CoreVideo/CoreVideo.h>
#import "SGPLFGLContext.h"

#if SGPLATFORM_TARGET_OS_MAC

#import <OpenGL/gl.h>
#import <OpenGL/glext.h>

typedef CVOpenGLTextureRef SGPLFGLCVOpenGLTextureRef;
typedef CVOpenGLTextureCacheRef SGPLFGLCVOpenGLTextureCacheRef;

#elif SGPLATFORM_TARGET_OS_IPHONE

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

typedef CVOpenGLESTextureRef SGPLFGLCVOpenGLTextureRef;
typedef CVOpenGLESTextureCacheRef SGPLFGLCVOpenGLTextureCacheRef;

#endif

CV_EXPORT CVReturn SGPLFGLCVOpenGLTextureCacheCreate(SGPLFGLContext * context, SGPLFGLCVOpenGLTextureCacheRef * cacheRef);

CV_EXPORT GLenum SGPLFGLCVOpenGLTextureGetTarget(SGPLFGLCVOpenGLTextureRef image);
CV_EXPORT GLenum SGPLFGLCVOpenGLTextureGetName(SGPLFGLCVOpenGLTextureRef image);

CV_EXPORT void SGPLFGLCVOpenGLTextureCacheFlush(SGPLFGLCVOpenGLTextureCacheRef textureCache, CVOptionFlags options);
