//
//  SGPlayer.m
//  SGPlayer
//
//  Created by Single on 16/6/28.
//  Copyright © 2016年 single. All rights reserved.
//

#import "SGPlayer.h"
#import "SGPlayerMacro.h"
#import "SGNotification.h"
#import "SGDisplayView.h"
#import "SGAVPlayer.h"
#import "SGFFPlayer.h"

@interface SGPlayer ()

@property (nonatomic, copy) void(^playerViewTapAction)();

@property (nonatomic, strong) SGDisplayView * displayView;
@property (nonatomic, assign) SGDecoderType decoderType;
@property (nonatomic, strong) SGAVPlayer * avPlayer;
@property (nonatomic, strong) SGFFPlayer * ffPlayer;

@end

@implementation SGPlayer

+ (instancetype)player
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
        self.decoder = [SGPlayerDecoder defaultDecoder];
        self.contentURL = nil;
        self.videoType = SGVideoTypeNormal;
        self.backgroundMode = SGPlayerBackgroundModeAutoPlayAndPause;
        self.displayMode = SGDisplayModeNormal;
        self.playableBufferInterval = 2.f;
        self.viewAnimationHidden = NO;
        self.volume = 1;
    }
    return self;
}

- (void)replaceVideoWithURL:(NSURL *)contentURL
{
    [self replaceVideoWithURL:contentURL videoType:SGVideoTypeNormal];
}

- (void)replaceVideoWithURL:(NSURL *)contentURL videoType:(SGVideoType)videoType
{
    self.contentURL = contentURL;
    self.decoderType = [self.decoder decoderTypeForContentURL:self.contentURL];
    self.videoType = videoType;
    
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            [self.avPlayer replaceVideo];
            if (_ffPlayer) {
                [self.ffPlayer stop];
            }
            break;
        case SGDecoderTypeFFmpeg:
            [self.ffPlayer replaceVideoWithURL:contentURL videoType:videoType];
            if (_avPlayer) {
                [self.avPlayer stop];
            }
            break;
        case SGDecoderTypeError:
            break;
    }
}

- (void)play
{
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            [self.avPlayer play];
            break;
        case SGDecoderTypeFFmpeg:
            [self.ffPlayer play];
            break;
        case SGDecoderTypeError:
            break;
    }
}

- (void)pause
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            [self.avPlayer pause];
            break;
        case SGDecoderTypeFFmpeg:
            [self.ffPlayer pause];
            break;
        case SGDecoderTypeError:
            break;
    }
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completeHandler:nil];
}

- (void)seekToTime:(NSTimeInterval)time completeHandler:(void (^)(BOOL))completeHandler
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            [self.avPlayer seekToTime:time completeHandler:completeHandler];
            break;
        case SGDecoderTypeFFmpeg:
            [self.ffPlayer seekToTime:time completeHandler:completeHandler];
            break;
        case SGDecoderTypeError:
            break;
    }
}

- (void)setContentURL:(NSURL *)contentURL
{
    _contentURL = [contentURL copy];
}

- (void)setVideoType:(SGVideoType)videoType
{
    switch (videoType) {
        case SGVideoTypeNormal:
        case SGVideoTypeVR:
            _videoType = videoType;
            break;
        default:
            _videoType = SGVideoTypeNormal;
            break;
    }
}

- (void)setViewTapBlock:(void (^)())block
{
    self.playerViewTapAction = block;
}

- (void)setVolume:(CGFloat)volume
{
    _volume = volume;
    if (_avPlayer) {
        self.avPlayer.volume = volume;
    }
    if (_ffPlayer) {
        self.ffPlayer.volume = volume;
    }
}

- (SGPlayerState)state
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.state;
        case SGDecoderTypeFFmpeg:
            return self.ffPlayer.state;
        case SGDecoderTypeError:
            return SGPlayerStateNone;
    }
}

- (CGSize)presentationSize
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.presentationSize;
        case SGDecoderTypeFFmpeg:
            return self.ffPlayer.presentationSize;
        case SGDecoderTypeError:
            return CGSizeZero;
    }
}

- (NSTimeInterval)progress
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.progress;
        case SGDecoderTypeFFmpeg:
            return self.ffPlayer.progress;
        case SGDecoderTypeError:
            return 0;
    }
}

- (NSTimeInterval)duration
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.duration;
        case SGDecoderTypeFFmpeg:
            return self.ffPlayer.duration;
        case SGDecoderTypeError:
            return 0;
    }
}

- (NSTimeInterval)playableTime
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.playableTime;
        case SGDecoderTypeFFmpeg:
            return self.ffPlayer.playableTime;
        case SGDecoderTypeError:
            return 0;
    }
}

- (UIImage *)snapshot
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.snapshot;
        case SGDecoderTypeFFmpeg:
            return self.ffPlayer.snapshot;
        case SGDecoderTypeError:
            return nil;
    }
}

- (BOOL)seeking
{
    switch (self.decoderType) {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.seeking;
        case SGDecoderTypeFFmpeg:
            return self.ffPlayer.seeking;
        case SGDecoderTypeError:
            return NO;
    }
}

- (UIView *)view
{
    return self.displayView;
}

- (SGDisplayView *)displayView
{
    if (!_displayView) {
        _displayView = [[SGDisplayView alloc] initWithFrame:CGRectZero];
    }
    return _displayView;
}

- (void)tapAction
{
    if (self.playerViewTapAction) {
        SGPlayerLog(@"SGPlayer tap action");
        self.playerViewTapAction();
    }
}

- (SGAVPlayer *)avPlayer
{
    if (!_avPlayer) {
        _avPlayer = [SGAVPlayer playerWithAbstractPlayer:self];
        _avPlayer.volume = self.volume;
    }
    return _avPlayer;
}

- (SGFFPlayer *)ffPlayer
{
    if (!_ffPlayer) {
        _ffPlayer = [SGFFPlayer player];
        [self setupPlayerView:self.ffPlayer.view];
        _ffPlayer.abstractPlayer = self;
        _ffPlayer.displayMode = self.displayMode;
        [_ffPlayer setViewTapBlock:self.playerViewTapAction];
        _ffPlayer.volume = self.volume;
        _ffPlayer.viewAnimationHidden = self.viewAnimationHidden;
        _ffPlayer.playableBufferInterval = self.playableBufferInterval;
        _ffPlayer.backgroundMode = self.backgroundMode;
    }
    return _ffPlayer;
}

- (void)setupPlayerView:(UIView *)playerView;
{
    [self cleanPlayerView];
    if (playerView) {
        [self.view addSubview:playerView];
        
        playerView.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSLayoutConstraint * top = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0];
        NSLayoutConstraint * bottom = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
        NSLayoutConstraint * left = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
        NSLayoutConstraint * right = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:0];
        
        [self.view addConstraint:top];
        [self.view addConstraint:bottom];
        [self.view addConstraint:left];
        [self.view addConstraint:right];
    }
}

- (void)cleanPlayer
{
    if (_avPlayer) {
        [self.avPlayer stop];
        self.avPlayer = nil;
    }
    if (_ffPlayer) {
        [self.ffPlayer stop];
        self.ffPlayer = nil;
    }
    [self cleanPlayerView];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)cleanPlayerView
{
    [self.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
}

- (void)dealloc
{
    SGPlayerLog(@"SGPlayer release");
    [self cleanPlayer];
}

@end
