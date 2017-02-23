//
//  SGPLFGLContext.h
//  SGMediaKit
//
//  Created by Single on 2017/2/23.
//  Copyright © 2017年 single. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "SGPLFMacro.h"

#if SGPLATFORM_OS_MOBILE

#ifndef SGPLFGLContext
#define SGPLFGLContext EAGLContext
#endif

#ifndef SGPLFGLContext_Alloc_Init
#define SGPLFGLContext_Alloc_Init [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]
#endif

#elif SGPLATFORM_OS_MAC

#ifndef SGPLFGLContext_Alloc_Init
#define SGPLFGLContext_Alloc_Init [[SGPLFGLContext alloc] init]
#endif

@interface SGPLFGLContext : NSObject

+ (void)setCurrentContext:(SGPLFGLContext *)context;

@end

#endif
