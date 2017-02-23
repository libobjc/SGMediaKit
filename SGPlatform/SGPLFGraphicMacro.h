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

#if SGPLATFORM_OS_MAC

#import <Cocoa/Cocoa.h>

#define SGPLFView NSView
#define SGPLFImage NSImage

#else

#import <UIKit/UIKit.h>

#define SGPLFView UIView
#define SGPLFImage UIImage

#endif

#endif /* SGPLFGraphicMacro_h */
