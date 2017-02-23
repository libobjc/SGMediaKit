//
//  SGPLFGraphicMacro.h
//  SGMediaKit
//
//  Created by Single on 2017/2/23.
//  Copyright © 2017年 single. All rights reserved.
//

#ifndef SGPLFGraphicMacro_h
#define SGPLFGraphicMacro_h

#import "SGPLFMacro.h"

// type define

#if SGPLATFORM_OS_MAC

#import <Cocoa/Cocoa.h>

#define SGPLFView NSView
#define SGPLFImage NSImage

// OpenGL
#define SGPLFGLView NSView

#elif SGPLATFORM_OS_MOBILE

#import <UIKit/UIKit.h>

#define SGPLFView UIView
#define SGPLFImage UIImage

// OpenGL ES
#define SGPLFGLView GLKView

#endif


// tools

#if SGPLATFORM_OS_MAC

#define SGPLFImageWithCGImage(image) [[NSImage alloc] initWithCGImage:image size:CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image))]

#elif SGPLATFORM_OS_MOBILE

#define SGPLFImageWithCGImage(CGImage) [UIImage imageWithCGImage:CGImage]

#endif

#endif /* SGPLFGraphicMacro_h */
