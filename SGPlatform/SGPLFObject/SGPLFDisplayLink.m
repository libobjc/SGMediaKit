//
//  SGPLFDisplayLink.m
//  SGMediaKit
//
//  Created by Single on 2017/2/24.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFDisplayLink.h"

#if SGPLATFORM_TARGET_OS_MAC

@implementation SGPLFDisplayLink

+ (SGPLFDisplayLink *)displayLinkWithTarget:(id)target selector:(SEL)selector
{
    return nil;
}

- (void)addToRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode
{
    
}

- (void)invalidate
{
    
}

@end

#endif


