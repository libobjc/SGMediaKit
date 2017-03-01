//
//  SGPLFGLView.h
//  SGMediaKit
//
//  Created by Single on 2017/2/23.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFMacro.h"
#import <GLKit/GLKit.h>

#import "SGPLFGLContext.h"
#import "SGPLFImage.h"

#if SGPLATFORM_TARGET_OS_MAC

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

typedef NSOpenGLView SGPLFGLView;

#elif SGPLATFORM_TARGET_OS_IPHONE

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

typedef GLKView SGPLFGLView;

#endif

void SGPLFGLViewPrepareOpenGL(SGPLFGLView * view);
void SGPLFGLViewFlushBuffer(SGPLFGLView * view);
void SGPLFGLViewBindFrameBuffer(SGPLFGLView * view);

void SGPLFGLViewSetContext(SGPLFGLView * view, SGPLFGLContext * context);
SGPLFGLContext * SGPLFGLViewGetContext(SGPLFGLView * view);

SGPLFImage * SGPLFGLViewGetCurrentSnapshot(SGPLFGLView * view);
