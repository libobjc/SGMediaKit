//
//  SGPLFGLView.m
//  SGMediaKit
//
//  Created by Single on 2017/2/23.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFGLView.h"
#import "SGPLFView.h"
#import "SGPLFScreen.h"

#if SGPLATFORM_TARGET_OS_MAC

void SGPLFGLViewBindFrameBuffer(SGPLFGLView * view)
{
    
}

void SGPLFGLViewPrepareOpenGL(SGPLFGLView * view)
{
    SGPLFGLContext * context = SGPLFGLViewGetContext(view);
    SGPLGLContextSetCurrentContext(context);
}

void SGPLFGLViewFlushBuffer(SGPLFGLView * view)
{
    [view.openGLContext flushBuffer];
}

void SGPLFGLViewSetContext(SGPLFGLView * view, SGPLFGLContext * context)
{
    view.openGLContext = context;
}

SGPLFGLContext * SGPLFGLViewGetContext(SGPLFGLView * view)
{
    return view.openGLContext;
}

SGPLFImage * SGPLFGLViewGetCurrentSnapshot(SGPLFGLView * view)
{
    return SGPLFViewGetCurrentSnapshot(view);
}

#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV

void SGPLFGLViewBindFrameBuffer(SGPLFGLView * view)
{
    [view bindDrawable];
}

void SGPLFGLViewPrepareOpenGL(SGPLFGLView * view)
{
    SGPLFGLContext * context = SGPLFGLViewGetContext(view);
    SGPLGLContextSetCurrentContext(context);
}

void SGPLFGLViewFlushBuffer(SGPLFGLView * view)
{
    if (view.enableSetNeedsDisplay) {
        [view setNeedsDisplay];
    } else {
        [view display];
    }
}

void SGPLFGLViewSetContext(SGPLFGLView * view, SGPLFGLContext * context)
{
    view.context = context;
}

SGPLFGLContext * SGPLFGLViewGetContext(SGPLFGLView * view)
{
    return view.context;
}

SGPLFImage * SGPLFGLViewGetCurrentSnapshot(SGPLFGLView * view)
{
    return view.snapshot;
}

#endif
