//
//  SGPLFGLView.m
//  SGMediaKit
//
//  Created by Single on 2017/2/23.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFGLView.h"

#if SGPLATFORM_TARGET_OS_MAC

@implementation SGPLFGLView

- (SGPLFImage *)snapshot
{
    return nil;
}

- (void)bindDrawable
{
    
}

- (void)glDisplay
{
    NSLog(@"%s", __func__);
}

@end

void SGPLFGLViewDisplay(SGPLFGLView * view)
{
    [view glDisplay];
}

#elif SGPLATFORM_TARGET_OS_IPHONE

void SGPLFGLViewDisplay(SGPLFGLView * view)
{
    [view display];
}

#endif
