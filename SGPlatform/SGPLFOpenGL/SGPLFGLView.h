//
//  SGPLFGLView.h
//  SGMediaKit
//
//  Created by Single on 2017/2/23.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFMacro.h"

#import "SGPLFGLContext.h"
#import "SGPLFImage.h"

#if SGPLATFORM_TARGET_OS_MAC

#import <Cocoa/Cocoa.h>

typedef NSOpenGLView SGPLFGLView;

#elif SGPLATFORM_TARGET_OS_IPHONE

#import <GLKit/GLKit.h>

typedef GLKView SGPLFGLView;

#endif

void SGPLFGLViewPrepareOpenGL(SGPLFGLView * view);
void SGPLFGLViewFlushBuffer(SGPLFGLView * view);
void SGPLFGLViewBindFrameBuffer(SGPLFGLView * view);

void SGPLFGLViewSetContext(SGPLFGLView * view, SGPLFGLContext * context);
SGPLFGLContext * SGPLFGLViewGetContext(SGPLFGLView * view);

SGPLFImage * SGPLFGLViewGetCurrentSnapshot(SGPLFGLView * view);
