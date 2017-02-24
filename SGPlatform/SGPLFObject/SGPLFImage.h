//
//  SGPLFImage.h
//  SGMediaKit
//
//  Created by Single on 2017/2/24.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFMacro.h"

#if SGPLATFORM_TARGET_OS_MAC

#import <Cocoa/Cocoa.h>

typedef NSImage SGPLFImage;

#elif SGPLATFORM_TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

typedef UIImage SGPLFImage;

#endif

SGPLFImage * SGPLFImageWithCGImage(CGImageRef image);
