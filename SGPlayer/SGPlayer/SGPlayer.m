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
#import "SGAVPlayer.h"

#define kSGVideoTypeError 1900

typedef NS_ENUM(NSUInteger, SGPlayerType) {
    SGPlayerTypeUnknown,    // unsupport video type
    SGPlayerTypeAVPlayer,   // normal or vr video
};

@interface SGPlayer ()

@property (nonatomic, copy) void(^playerViewTapAction)();
@property (nonatomic, assign, readonly) SGPlayerType playerType;
@property (nonatomic, strong) SGAVPlayer * avPlayer;

@end

@implementation SGPlayer

@synthesize view = _view;

+ (instancetype)playerWithURL:(NSURL *)contentURL
{
    return [[self alloc] initWithURL:contentURL];
}

+ (instancetype)playerWithURL:(NSURL *)contentURL videoType:(SGVideoType)videoType
{
    return [[self alloc] initWithURL:contentURL videoType:videoType];
}

- (instancetype)init
{
    return [self initWithURL:nil];
}

- (instancetype)initWithURL:(NSURL *)contentURL
{
    return [self initWithURL:contentURL videoType:SGVideoTypeNormal];
}

- (instancetype)initWithURL:(NSURL *)contentURL videoType:(SGVideoType)videoType
{
    if (self = [super init]) {
        self.contentURL = contentURL;
        self.videoType = videoType;
        self.identifier = SGPlayerDefaultIdentifier;
        self.backgroundMode = SGPlayerBackgroundModeAutoPlayAndPause;
        self.displayMode = SGDisplayModeNormal;
        [self setupPlayer];
    }
    return self;
}

- (void)replaceVideoWithURL:(NSURL *)contentURL
{
    [self replaceVideoWithURL:contentURL videoType:SGVideoTypeNormal];
}

- (void)replaceVideoWithURL:(NSURL *)contentURL videoType:(SGVideoType)videoType
{
    SGPlayerType beforePlayerType = self.playerType;
    self.contentURL = contentURL;
    self.videoType = videoType;
    
    if (beforePlayerType == self.playerType == SGPlayerTypeAVPlayer)
    {
        // SGAVPlayer
        [self.avPlayer replaceVideoWithURL:contentURL videoType:videoType];
    }
    else
    {
        [self setupPlayer];
    }
}

- (SGPlayerState)state
{
    switch (self.playerType) {
        case SGPlayerTypeAVPlayer:
        {
            return self.avPlayer.state;
        }
        case SGPlayerTypeUnknown:
        {
            return SGPlayerStateFailed;
        }
    }
}

- (void)play
{
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    switch (self.playerType) {
        case SGPlayerTypeAVPlayer:
        {
            [self.avPlayer play];
        }
            break;
        case SGPlayerTypeUnknown:
        {
            
        }
            break;
    }
}

- (void)pause
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    switch (self.playerType) {
        case SGPlayerTypeAVPlayer:
        {
            [self.avPlayer pause];
        }
            break;
        case SGPlayerTypeUnknown:
        {
            
        }
            break;
    }
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completeHandler:nil];
}

- (void)seekToTime:(NSTimeInterval)time completeHandler:(void (^)(BOOL))completeHandler
{
    switch (self.playerType) {
        case SGPlayerTypeAVPlayer:
        {
            [self.avPlayer seekToTime:time completeHandler:completeHandler];
        }
            break;
        case SGPlayerTypeUnknown:
        {
            
        }
            break;
    }
}

- (void)setVolume:(CGFloat)volume
{
    switch (self.playerType) {
        case SGPlayerTypeAVPlayer:
        {
            self.avPlayer.volume = volume;
        }
        case SGPlayerTypeUnknown:
        {
            
        }
    }
}

- (CGFloat)volume
{
    switch (self.playerType) {
        case SGPlayerTypeAVPlayer:
        {
            return self.avPlayer.volume;
        }
        case SGPlayerTypeUnknown:
        {
            return 0;
        }
    }
}

- (void)setViewAnimationHidden:(BOOL)viewAnimationHidden
{
    switch (self.playerType) {
        case SGPlayerTypeAVPlayer:
        {
            self.avPlayer.viewAnimationHidden = viewAnimationHidden;
        }
        case SGPlayerTypeUnknown:
        {
            
        }
    }
}

- (BOOL)viewAnimationHidden
{
    switch (self.playerType) {
        case SGPlayerTypeAVPlayer:
        {
            return self.avPlayer.viewAnimationHidden;
        }
        case SGPlayerTypeUnknown:
        {
            return NO;
        }
    }
}

- (NSTimeInterval)progress
{
    switch (self.playerType) {
        case SGPlayerTypeAVPlayer:
        {
            return self.avPlayer.progress;
        }
        case SGPlayerTypeUnknown:
        {
            return 0;
        }
    }
}

- (NSTimeInterval)duration
{
    switch (self.playerType) {
        case SGPlayerTypeAVPlayer:
        {
            return self.avPlayer.duration;
        }
        case SGPlayerTypeUnknown:
        {
            return 0;
        }
    }
}

- (NSTimeInterval)playableTime
{
    switch (self.playerType) {
        case SGPlayerTypeAVPlayer:
        {
            return self.avPlayer.playableTime;
        }
        case SGPlayerTypeUnknown:
        {
            return 0;
        }
    }
}

- (NSTimeInterval)playableBufferInterval
{
    switch (self.playerType) {
        case SGPlayerTypeAVPlayer:
        {
            return self.avPlayer.playableBufferInterval;
        }
        case SGPlayerTypeUnknown:
        {
            return 0;
        }
    }
}

- (UIImage *)snapshot
{
    switch (self.playerType) {
        case SGPlayerTypeAVPlayer:
        {
            return self.avPlayer.snapshot;
        }
        case SGPlayerTypeUnknown:
        {
            return nil;
        }
    }
}

- (void)setPlayableBufferInterval:(NSTimeInterval)playableBufferInterval
{
    switch (self.playerType) {
        case SGPlayerTypeAVPlayer:
        {
            self.avPlayer.playableBufferInterval = playableBufferInterval;
        }
            break;
        case SGPlayerTypeUnknown:
        {
            
        }
            break;
    }
}

- (void)setContentURL:(NSURL *)contentURL
{
    _contentURL = contentURL;
}

- (void)setVideoType:(SGVideoType)videoType
{
    switch (videoType) {
        case SGVideoTypeNormal:
        case SGVideoTypeVR:
        {
            _videoType = videoType;
        }
            break;
        default:
        {
            _videoType = kSGVideoTypeError;
        }
            break;
    }
}

- (BOOL)seeking
{
    switch (self.playerType) {
        case SGPlayerTypeAVPlayer:
        {
            return self.avPlayer.seeking;
        }
            break;
        case SGPlayerTypeUnknown:
        {
            return NO;
        }
            break;
    }
}

- (SGPlayerType)playerType
{
    switch (_videoType) {
        case SGVideoTypeNormal:
        case SGVideoTypeVR:
        {
            return SGPlayerTypeAVPlayer;
        }
        default:
        {
            return SGPlayerTypeUnknown;
        }
    }
}

- (UIView *)view
{
    if (!_view) {
        _view = [[UIView alloc] initWithFrame:CGRectZero];
        _view.backgroundColor = [UIColor blackColor];
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
        [_view addGestureRecognizer:tap];
    }
    return _view;
}

- (void)tapAction
{
    if (self.playerViewTapAction) {
        SGLog(@"SGPlayer tap action");
        self.playerViewTapAction();
    }
}

- (void)setViewTapBlock:(void (^)())block
{
    self.playerViewTapAction = block;
    [self setupPlayerViewTapAction];
}

- (void)setDisplayMode:(SGDisplayMode)displayMode
{
    _displayMode = displayMode;
    switch (self.playerType) {
        case SGPlayerTypeAVPlayer:
        {
            self.avPlayer.displayMode = displayMode;
        }
            break;
        case SGPlayerTypeUnknown:
        {
            
        }
            break;
    }
}

- (void)setupPlayer
{
    [self clearPlayer];
    switch (self.playerType) {
        case SGPlayerTypeAVPlayer:
        {
            self.avPlayer = [SGAVPlayer playerWithURL:self.contentURL videoType:self.videoType];
            [self setupPlayerView:self.avPlayer.view];
            self.avPlayer.abstractPlayer = self;
            self.avPlayer.displayMode = self.displayMode;
        }
            break;
        case SGPlayerTypeUnknown:
        {
            [self playerError];
        }
            break;
    }
    if (self.playerViewTapAction) {
        [self setupPlayerViewTapAction];
    }
}

- (void)clearPlayer
{
    if (self.avPlayer) {
        [self.avPlayer stop];
        self.avPlayer = nil;
    }
    [self clearPlayerView];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)setupPlayerView:(UIView *)playerView;
{
    [self clearPlayerView];
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

- (void)clearPlayerView
{
    [self.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
}

- (void)setupPlayerViewTapAction
{
    switch (self.playerType) {
        case SGPlayerTypeAVPlayer:
        {
            [self.avPlayer setViewTapBlock:self.playerViewTapAction];
        }
            break;
        case SGPlayerTypeUnknown:
        {
            
        }
            break;
    }
}

- (void)playerError
{
    [self clearPlayer];
    SGLog(@"SGPlayer unsupport video type");
    [SGNotification postPlayer:self errorMessage:@"unsupport video type" code:1901];
}

- (void)dealloc
{
    SGLog(@"SGPlayer release");
    [self clearPlayer];
}

@end
