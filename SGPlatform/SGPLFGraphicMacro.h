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

#if SGPLATFORM_TARGET_OS_MAC

#import <Cocoa/Cocoa.h>

#define SGPLFView NSView
#define SGPLFImage NSImage

#elif SGPLATFORM_TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

#define SGPLFView UIView
#define SGPLFImage UIImage

#endif


// tools

#if SGPLATFORM_TARGET_OS_MAC

#define SGPLFImageWithCGImage(image) [[NSImage alloc] initWithCGImage:image size:CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image))]

#elif SGPLATFORM_TARGET_OS_IPHONE

#define SGPLFImageWithCGImage(CGImage) [UIImage imageWithCGImage:CGImage]

#endif

#endif /* SGPLFGraphicMacro_h */
