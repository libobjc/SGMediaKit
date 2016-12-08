//
//  SGAVView.m
//  SGPlayer
//
//  Created by Single on 16/6/29.
//  Copyright © 2016年 single. All rights reserved.
//

#import "SGAVView.h"
#import "SGPlayerMacro.h"

@interface SGAVView () <SGAVGLViewDelegate>

@property (nonatomic, weak) AVPlayer * player;
@property (nonatomic, strong) AVPlayerLayer * graphicsLayer;
@property (nonatomic, assign) BOOL graphicsLayerAnimationHidden;    // default is NO
@property (nonatomic, strong) SGAVGLView * graphicsView;
@property (nonatomic, assign) SGDisplayMode displayMode;

@end

@implementation SGAVView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)resume
{
    if (self.graphicsView) {
        self.graphicsView.paused = NO;
    }
    if (self.graphicsLayer) {
        self.graphicsLayer.player = self.player;
    }
}

- (void)pause
{
    if (self.graphicsView) {
        self.graphicsView.paused = NO;
    }
    if (self.graphicsLayer) {
        self.graphicsLayer.player = self.player;
    }
}

- (void)tapAction
{
    if (self.tapActionBlock) {
        SGPlayerLog(@"SGView tap action");
        self.tapActionBlock();
    }
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    [super layoutSublayersOfLayer:layer];
    
    if (self.graphicsLayer) {
        self.graphicsLayer.frame = layer.bounds;
        if (self.graphicsLayerAnimationHidden) {
            [self.graphicsLayer removeAllAnimations];
        }
    }
    if (self.graphicsView) {
        CGSize size = layer.bounds.size;
        if (size.width < size.height) {
            self.graphicsView.frame = CGRectMake(0, (size.height-size.width/16*9)/2, size.width, size.width/16*9);
        } else {
            self.graphicsView.frame = layer.bounds;
        }
    }
}

- (void)setPlayerForAVPlayerLayer:(AVPlayer *)player animationHidden:(BOOL)animationHidden
{
    self.player = player;
    self.graphicsLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [self setAnimationHiddenForAVPlayerLayer:animationHidden];
}

- (void)setAnimationHiddenForAVPlayerLayer:(BOOL)animationHidden
{
    self.graphicsLayerAnimationHidden = animationHidden;
}

- (void)setPlayerForSGAVGLView:(AVPlayer *)player dataSource:(id<SGAVGLViewDataSource>)dataSource displayMode:(SGDisplayMode)displayMode
{
    self.player = player;
    self.graphicsView = [[SGAVGLView alloc] initWithFrame:CGRectZero];
    self.graphicsView.sgDelegate = self;
    self.graphicsView.dataSource = dataSource;
    [self setDisplayModeForSGAVGLView:displayMode];
}

- (void)sgav_glViewTapAction:(SGAVGLView *)glView
{
    [self tapAction];
}

- (void)setDisplayModeForSGAVGLView:(SGDisplayMode)displayMode
{
    self.displayMode = displayMode;
}

- (void)setDisplayMode:(SGDisplayMode)displayMode
{
    _displayMode = displayMode;
    self.graphicsView.displayMode = displayMode;
}

- (void)setGraphicsLayer:(AVPlayerLayer *)graphicsLayer
{
    [self clearGraphicsView];
    if (_graphicsLayer != graphicsLayer) {
        [self clearGraphicsLayer];
        _graphicsLayer = graphicsLayer;
        [self.layer insertSublayer:graphicsLayer atIndex:0];
    }
}

- (void)setGraphicsView:(SGAVGLView *)graphicsView
{
    [self clearGraphicsLayer];
    if (_graphicsView != graphicsView) {
        [self clearGraphicsView];
        _graphicsView = graphicsView;
        [self insertSubview:self.graphicsView atIndex:0];
    }
}

- (UIImage *)glViewSnapshot
{
    return self.graphicsView.snapshot;
}

- (void)clearGraphicsLayer
{
    if (_graphicsLayer) {
        [_graphicsLayer removeFromSuperlayer];
        _graphicsLayer = nil;
    }
}

- (void)clearGraphicsView
{
    if (_graphicsView) {
        [_graphicsView invalidate];
        [_graphicsView removeFromSuperview];
        _graphicsView = nil;
    }
}

- (void)clear
{
    [self clearGraphicsLayer];
    [self clearGraphicsView];
}

- (void)dealloc
{
    SGPlayerLog(@"SGAVView release");
}

@end
