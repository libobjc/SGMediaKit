//
//  SGPLFGLContext.m
//  SGMediaKit
//
//  Created by Single on 2017/2/23.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFGLContext.h"

#if SGPLATFORM_TARGET_OS_IPHONE

SGPLFGLContext * SGPLFGLContext_Alloc_Init()
{
    return [[SGPLFGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
}

#elif SGPLATFORM_TARGET_OS_MAC

@implementation SGPLFGLContext

SGPLFGLContext * SGPLFGLContext_Alloc_Init()
{
    return [[SGPLFGLContext alloc] init];
}

@end

#endif
