//
//  SGPLFGLView.h
//  SGMediaKit
//
//  Created by Single on 2017/2/23.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFMacro.h"
#import <GLKit/GLKit.h>

#if SGPLATFORM_OS_MOBILE

#define SGPLFGLView GLKView
#define SGPLFGLViewDelegate GLKViewDelegate

#elif SGPLATFORM_OS_MAC

@protocol SGPLFGLViewDelegate <NSObject>

- (void)glkView:(SGPLFGLView *)view drawInRect:(CGRect)rect;

@end

@interface SGPLFGLView : NSView

@end

#endif
