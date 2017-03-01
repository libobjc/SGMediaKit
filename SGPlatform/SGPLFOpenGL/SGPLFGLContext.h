//
//  SGPLFGLContext.h
//  SGMediaKit
//
//  Created by Single on 2017/2/23.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFMacro.h"
#import <GLKit/GLKit.h>

#if SGPLATFORM_TARGET_OS_MAC

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

typedef NSOpenGLContext SGPLFGLContext;

NSOpenGLPixelFormat * SGPLFGLContextGetPixelFormat(SGPLFGLContext * context);

#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

typedef EAGLContext SGPLFGLContext;

#endif

SGPLFGLContext * SGPLFGLContextAllocInit();
void SGPLGLContextSetCurrentContext(SGPLFGLContext * context);
