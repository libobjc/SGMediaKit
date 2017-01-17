//
//  SGDisplayView.m
//  SGMediaKit
//
//  Created by Single on 12/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGDisplayView.h"
#import "SGPlayer.h"
#import "SGAVPlayer.h"
#import "SGGLAVView.h"
#import "SGGLFFView.h"

@interface SGDisplayView ()

@property (nonatomic, weak) SGPlayer * abstractPlayer;

@property (nonatomic, strong) AVPlayerLayer * avplayerLayer;
@property (nonatomic, strong) SGGLAVView * avplayerView;
@property (nonatomic, strong) SGGLFFView * ffplayerView;
@property (nonatomic, strong) UITapGestureRecognizer * tapGestureRecigbuzer;

@end

@implementation SGDisplayView

+ (instancetype)displayViewWithAbstractPlayer:(SGPlayer *)abstractPlayer
{
    return [[self alloc] initWithAbstractPlayer:abstractPlayer];
}

- (instancetype)initWithAbstractPlayer:(SGPlayer *)abstractPlayer
{
    if (self = [super initWithFrame:CGRectZero]) {
        self.abstractPlayer = abstractPlayer;
        [self UILayout];
    }
    return self;
}

- (void)UILayout
{
    self.backgroundColor = [UIColor blackColor];
    self.tapGestureRecigbuzer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecigbuzerAction:)];
    [self addGestureRecognizer:self.tapGestureRecigbuzer];
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    [super layoutSublayersOfLayer:layer];
    
    if (self.avplayerLayer) {
        self.avplayerLayer.frame = layer.bounds;
        if (self.abstractPlayer.viewAnimationHidden) {
            [self.avplayerLayer removeAllAnimations];
        }
    }
    if (self.avplayerView) {
        CGSize size = layer.bounds.size;
        if (size.width < size.height) {
            self.avplayerView.frame = CGRectMake(0, (size.height-size.width/16*9)/2, size.width, size.width/16*9);
        } else {
            self.avplayerView.frame = layer.bounds;
        }
    }
    if (self.ffplayerView) {
        CGSize size = layer.bounds.size;
        if (size.width < size.height) {
            self.ffplayerView.frame = CGRectMake(0, (size.height-size.width/16*9)/2, size.width, size.width/16*9);
        } else {
            self.ffplayerView.frame = layer.bounds;
        }
    }
}

- (void)renderFrame:(SGFFVideoFrame *)displayFrame
{
    [self.ffplayerView renderFrame:displayFrame];
}

- (void)setRendererType:(SGDisplayRendererType)rendererType
{
    if (_rendererType != rendererType) {
        _rendererType = rendererType;
        [self reloadView];
    }
}

- (void)reloadView
{
    [self cleanViewIgnore];
    switch (self.rendererType) {
        case SGDisplayRendererTypeEmpty:
            break;
        case SGDisplayRendererTypeAVPlayerLayer:
            if (!self.avplayerLayer) {
                self.avplayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.sgavplayer.avPlayer];
                [self.layer insertSublayer:self.avplayerLayer atIndex:0];
            }
            break;
        case SGDisplayRendererTypeAVPlayerPixelBufferVR:
            if (!self.avplayerView) {
                self.avplayerView = [SGGLAVView viewWithDisplayView:self];
                [self insertSubview:self.avplayerView atIndex:0];
            }
            break;
        case SGDisplayRendererTypeFFmpegPexelBuffer:
        case SGDisplayRendererTypeFFmpegPexelBufferVR:
            if (!self.ffplayerView) {
                self.ffplayerView = [SGGLFFView viewWithDisplayView:self];
                [self insertSubview:self.ffplayerView atIndex:0];
            }
            break;
    }
}

- (void)cleanView
{
    [self cleanViewCleanAVPlayerLayer:YES cleanAVPlayerView:YES cleanFFPlayerView:YES];
}

- (void)cleanViewIgnore
{
    switch (self.rendererType) {
        case SGDisplayRendererTypeEmpty:
            [self cleanView];
            break;
        case SGDisplayRendererTypeAVPlayerLayer:
            [self cleanViewCleanAVPlayerLayer:NO cleanAVPlayerView:YES cleanFFPlayerView:YES];
            break;
        case SGDisplayRendererTypeAVPlayerPixelBufferVR:
            [self cleanViewCleanAVPlayerLayer:YES cleanAVPlayerView:NO cleanFFPlayerView:YES];
            break;
        case SGDisplayRendererTypeFFmpegPexelBuffer:
        case SGDisplayRendererTypeFFmpegPexelBufferVR:
            [self cleanViewCleanAVPlayerLayer:YES cleanAVPlayerView:YES cleanFFPlayerView:NO];
            break;
    }
}

- (void)cleanViewCleanAVPlayerLayer:(BOOL)cleanAVPlayerLayer cleanAVPlayerView:(BOOL)cleanAVPlayerView cleanFFPlayerView:(BOOL)cleanFFPlayerView
{
    [self cleanEmptyBuffer];
    if (cleanAVPlayerLayer && self.avplayerLayer) {
        [self.avplayerLayer removeFromSuperlayer];
        self.avplayerLayer = nil;
    }
    if (cleanAVPlayerView && self.avplayerView) {
        [self.avplayerView invalidate];
        [self.avplayerView removeFromSuperview];
        self.avplayerView = nil;
    }
    if (cleanFFPlayerView && self.ffplayerView) {
        [self.ffplayerView removeFromSuperview];
        self.ffplayerView = nil;
    }
}

- (void)resume
{
    NSLog(@"%s", __func__);
}

- (void)pause
{
    NSLog(@"%s", __func__);
}

- (void)cleanEmptyBuffer
{
    [self.fingerRotation clean];
    if (self.avplayerView) {
        [self.avplayerView cleanEmptyBuffer];
    }
    if (self.ffplayerView) {
        [self.ffplayerView cleanEmptyBuffer];
    }
}

- (SGFingerRotation *)fingerRotation
{
    if (!_fingerRotation) {
        _fingerRotation = [SGFingerRotation fingerRotation];
    }
    return _fingerRotation;
}

- (UIImage *)snapshot
{
    switch (self.rendererType) {
        case SGDisplayRendererTypeEmpty:
            return nil;
        case SGDisplayRendererTypeAVPlayerLayer:
            return self.sgavplayer.snapshotAtCurrentTime;
        case SGDisplayRendererTypeAVPlayerPixelBufferVR:
            return self.avplayerView.snapshot;
        case SGDisplayRendererTypeFFmpegPexelBuffer:
        case SGDisplayRendererTypeFFmpegPexelBufferVR:
            return self.ffplayerView.snapshot;
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.abstractPlayer.displayMode == SGDisplayModeBox) return;
    switch (self.rendererType) {
        case SGDisplayRendererTypeEmpty:
        case SGDisplayRendererTypeAVPlayerLayer:
            return;
        default:
        {
            UITouch * touch = [touches anyObject];
            float distanceX = [touch locationInView:touch.view].x - [touch previousLocationInView:touch.view].x;
            float distanceY = [touch locationInView:touch.view].y - [touch previousLocationInView:touch.view].y;
            distanceX *= 0.005;
            distanceY *= 0.005;
            self.fingerRotation.x += distanceY *  [SGFingerRotation degress] / 100;
            self.fingerRotation.y -= distanceX *  [SGFingerRotation degress] / 100;
        }
            break;
    }
}

- (void)tapGestureRecigbuzerAction:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (self.abstractPlayer.viewTapAction) {
        self.abstractPlayer.viewTapAction(self.abstractPlayer, self.abstractPlayer.view);
    }
}

@end
