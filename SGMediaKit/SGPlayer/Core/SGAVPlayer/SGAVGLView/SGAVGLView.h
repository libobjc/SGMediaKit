//
//  SGAVGLView.h
//  SGPlayer
//
//  Created by Single on 16/7/25.
//  Copyright © 2016年 Hanton. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "SGPlayerDefine.h"
@class SGAVGLView;

@protocol SGAVGLViewDelegate <NSObject>
- (void)sgav_glViewTapAction:(SGAVGLView *)glView;
@end

@protocol SGAVGLViewDataSource <NSObject>
- (CVPixelBufferRef)sgav_glViewPixelBufferToDraw:(SGAVGLView *)glView;
@end

@interface SGAVGLView : GLKView

@property (nonatomic, assign) BOOL paused;
@property (nonatomic, weak) id <SGAVGLViewDelegate> sgDelegate;
@property (nonatomic, weak) id <SGAVGLViewDataSource> dataSource;
@property (nonatomic, assign) SGDisplayMode displayMode;

- (void)invalidate;

@end
