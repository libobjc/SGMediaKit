//
//  SGAVView.h
//  SGPlayer
//
//  Created by Single on 16/6/29.
//  Copyright © 2016年 single. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "SGAVGLView.h"

@interface SGAVView : UIView

@property (nonatomic, copy) void(^tapActionBlock)();    // tap action

- (void)setPlayerForAVPlayerLayer:(AVPlayer *)player animationHidden:(BOOL)animationHidden;
- (void)setAnimationHiddenForAVPlayerLayer:(BOOL)animationHidden;

- (void)setPlayerForSGAVGLView:(AVPlayer *)player dataSource:(id <SGAVGLViewDataSource>)dataSource displayMode:(SGDisplayMode)displayMode;
- (void)setDisplayModeForSGAVGLView:(SGDisplayMode)displayMode;

- (UIImage *)glViewSnapshot;    // snapshot for vr video;
- (void)pause;
- (void)resume;
- (void)clear;

@end
