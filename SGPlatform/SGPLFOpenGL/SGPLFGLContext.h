//
//  SGPLFGLContext.h
//  SGMediaKit
//
//  Created by Single on 2017/2/23.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFMacro.h"

#if SGPLATFORM_TARGET_OS_MAC

#import <Cocoa/Cocoa.h>

typedef NSOpenGLContext SGPLFGLContext;

#elif SGPLATFORM_TARGET_OS_IPHONE

#import <GLKit/GLKit.h>

typedef EAGLContext SGPLFGLContext;

#endif

SGPLFGLContext * SGPLFGLContextAllocInit();
void SGPLGLContextSetCurrentContext(SGPLFGLContext * context);
