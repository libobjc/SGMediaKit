//
//  SGPLFGLContext.m
//  SGMediaKit
//
//  Created by Single on 2017/2/23.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFGLContext.h"

#if SGPLATFORM_TARGET_OS_MAC

SGPLFGLContext * SGPLFGLContextAllocInit()
{
    return [[NSOpenGLContext alloc] init];
}

void SGPLGLContextSetCurrentContext(SGPLFGLContext * context)
{
    if (context) {
        [context makeCurrentContext];
    } else {
        [NSOpenGLContext clearCurrentContext];
    }
}

#elif SGPLATFORM_TARGET_OS_IPHONE

SGPLFGLContext * SGPLFGLContextAllocInit()
{
    return [[SGPLFGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
}

void SGPLGLContextSetCurrentContext(SGPLFGLContext * context)
{
    [EAGLContext setCurrentContext:context];
}

#endif
