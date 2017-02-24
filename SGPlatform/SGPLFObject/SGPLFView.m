//
//  SGPLFView.m
//  SGMediaKit
//
//  Created by Single on 2017/2/24.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFView.h"

#if SGPLATFORM_TARGET_OS_MAC

void SGPLFViewSetBackgroundColor(SGPLFView * view, SGPLFColor * color)
{
    view.wantsLayer = YES;
    view.layer.backgroundColor = color.CGColor;
}

void SGPLFViewInsertSubview(SGPLFView * superView, SGPLFView * subView, NSInteger index)
{
    
}

#elif SGPLATFORM_TARGET_OS_IPHONE

void SGPLFViewSetBackgroundColor(SGPLFView * view, SGPLFColor * color)
{
    view.backgroundColor = color;
}

void SGPLFViewInsertSubview(SGPLFView * superView, SGPLFView * subView, NSInteger index)
{
    [superView insertSubview:subView atIndex:index];
}

#endif
