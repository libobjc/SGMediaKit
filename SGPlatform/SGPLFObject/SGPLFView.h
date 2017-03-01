//
//  SGPLFView.h
//  SGMediaKit
//
//  Created by Single on 2017/2/24.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFMacro.h"
#import "SGPLFColor.h"

#if SGPLATFORM_TARGET_OS_MAC

#import <Cocoa/Cocoa.h>

typedef NSView SGPLFView;

#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV

#import <UIKit/UIKit.h>

typedef UIView SGPLFView;

#endif

void SGPLFViewSetBackgroundColor(SGPLFView * view, SGPLFColor * color);
void SGPLFViewInsertSubview(SGPLFView * superView, SGPLFView * subView, NSInteger index);
