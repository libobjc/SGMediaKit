//
//  SGDisplayView.m
//  SGMediaKit
//
//  Created by Single on 12/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGDisplayView.h"
#import "SGPlayer.h"
#import "SGAVGLView.h"

@interface SGDisplayView () <SGAVGLViewDataSource>

@property (nonatomic, weak) SGPlayer * abstractPlayer;
@property (nonatomic, weak) AVPlayer * avplayer;
@property (nonatomic, weak) id <SGDisplayViewAVPlayerOutputDelgate> avplayerOutputDelegate;

@property (nonatomic, strong) AVPlayerLayer * avplayerLayer;
@property (nonatomic, strong) SGAVGLView * glView;

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
    if (self.glView) {
        CGSize size = layer.bounds.size;
        if (size.width < size.height) {
            self.glView.frame = CGRectMake(0, (size.height-size.width/16*9)/2, size.width, size.width/16*9);
        } else {
            self.glView.frame = layer.bounds;
        }
    }
}

- (void)renderFrame:(SGDisplayFrame *)displayFrame
{
    NSLog(@"%s", __func__);
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
                self.avplayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avplayer];
                [self.layer insertSublayer:self.avplayerLayer atIndex:0];
            }
            break;
        case SGDisplayRendererTypeAVPlayerPixelBufferVR:
        case SGDisplayRendererTypeFFmpegPexelBuffer:
        case SGDisplayRendererTypeFFmpegPexelBufferVR:
            if (!self.glView) {
                self.glView = [[SGAVGLView alloc] initWithFrame:CGRectZero];
                self.glView.dataSource = self;
                [self reloadDisplayMode];
                [self insertSubview:self.glView atIndex:0];
            }
            break;
    }
}

- (void)cleanView
{
    [self cleanViewCleanAVPlayerLayer:YES cleanView:YES];
}

- (void)cleanViewIgnore
{
    switch (self.rendererType) {
        case SGDisplayRendererTypeEmpty:
            [self cleanViewCleanAVPlayerLayer:YES cleanView:YES];
            break;
        case SGDisplayRendererTypeAVPlayerLayer:
            [self cleanViewCleanAVPlayerLayer:NO cleanView:YES];
            break;
        case SGDisplayRendererTypeAVPlayerPixelBufferVR:
        case SGDisplayRendererTypeFFmpegPexelBuffer:
        case SGDisplayRendererTypeFFmpegPexelBufferVR:
            [self cleanViewCleanAVPlayerLayer:YES cleanView:NO];
            break;
    }
}

- (void)cleanViewCleanAVPlayerLayer:(BOOL)cleanAVPlayerLayer cleanView:(BOOL)cleanView
{
    if (cleanAVPlayerLayer && self.avplayerLayer) {
        [self.avplayerLayer removeFromSuperlayer];
        self.avplayerLayer = nil;
    }
    if (cleanView && self.glView) {
        [self.glView invalidate];
        [self.glView removeFromSuperview];
        self.glView = nil;
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
    NSLog(@"%s", __func__);
}

- (void)reloadDisplayMode
{
    if (self.glView) {
        self.glView.displayMode = self.abstractPlayer.displayMode;
    }
}

- (void)setAVPlayer:(AVPlayer *)avplayer avplayerOutputDelegate:(id<SGDisplayViewAVPlayerOutputDelgate>)avplayerOutputDelegate
{
    self.avplayer = avplayer;
    self.avplayerOutputDelegate = avplayerOutputDelegate;
}

- (CVPixelBufferRef)sgav_glViewPixelBufferToDraw:(SGAVGLView *)glView
{
    if ([self.avplayerOutputDelegate respondsToSelector:@selector(displayViewFetchPixelBuffer:)]) {
        return [self.avplayerOutputDelegate displayViewFetchPixelBuffer:self];
    }
    return nil;
}

@end
