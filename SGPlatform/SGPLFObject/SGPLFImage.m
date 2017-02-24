//
//  SGPLFImage.m
//  SGMediaKit
//
//  Created by Single on 2017/2/24.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFImage.h"

#if SGPLATFORM_TARGET_OS_MAC

SGPLFImage * SGPLFImageWithCGImage(CGImageRef image)
{
    return [[NSImage alloc] initWithCGImage:image size:CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image))];
}

#elif SGPLATFORM_TARGET_OS_IPHONE

SGPLFImage * SGPLFImageWithCGImage(CGImageRef image)
{
    return [UIImage imageWithCGImage:image];
}

#endif

