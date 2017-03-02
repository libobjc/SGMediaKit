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
    if (superView.subviews.count > index) {
        NSView * obj = [superView.subviews objectAtIndex:index];
        [superView addSubview:subView positioned:NSWindowBelow relativeTo:obj];
    } else {
        [superView addSubview:subView];
    }
}

#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV

void SGPLFViewSetBackgroundColor(SGPLFView * view, SGPLFColor * color)
{
    view.backgroundColor = color;
}

void SGPLFViewInsertSubview(SGPLFView * superView, SGPLFView * subView, NSInteger index)
{
    [superView insertSubview:subView atIndex:index];
}

#endif
