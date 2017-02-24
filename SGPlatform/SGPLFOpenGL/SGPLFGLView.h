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

#if SGPLATFORM_TARGET_OS_IPHONE

typedef GLKView SGPLFGLView;

@protocol SGPLFGLViewDelegate <GLKViewDelegate>

@end

#elif SGPLATFORM_TARGET_OS_MAC

#import <Cocoa/Cocoa.h>

@class SGPLFGLView;

@protocol SGPLFGLViewDelegate <NSObject>

- (void)glkView:(SGPLFGLView *)view drawInRect:(CGRect)rect;

@end

@interface SGPLFGLView : NSView

@property (nonatomic, strong) SGPLFGLContext * context;

@end

#endif
