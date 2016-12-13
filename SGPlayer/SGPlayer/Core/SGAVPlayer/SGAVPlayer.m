//
//  SGAVPlayer.m
//  SGPlayer
//
//  Created by Single on 16/6/28.
//  Copyright © 2016年 single. All rights reserved.
//

#import "SGAVPlayer.h"
#import "SGPlayerMacro.h"
#import "SGNotification.h"
#import "SGAVView.h"
#import "SGAVGLView.h"

static CGFloat const PixelBufferRequestInterval = 0.03f;

@interface SGAVPlayer () <SGAVGLViewDataSource>

@property (nonatomic, strong) SGAVView * view;
@property (nonatomic, assign) SGPlayerState state;

@property (atomic, strong) id playBackTimeObserver;
@property (nonatomic, strong) AVPlayer * avPlayer;
@property (nonatomic, strong) AVPlayerItem * avPlayerItem;
@property (atomic, strong) AVAsset * avAsset;
@property (atomic, strong) AVPlayerItemVideoOutput * avOutput;
@property (atomic, assign) NSTimeInterval readyToPlayTime;

@property (atomic, assign) BOOL needPlay;        // seek and buffering use
@property (atomic, assign) BOOL autoNeedPlay;    // background use
@property (atomic, assign) BOOL hasPixelBuffer;

@end

@implementation SGAVPlayer

@synthesize playableTime = _playableTime;

#pragma mark - init

+ (instancetype)playerWithURL:(NSURL *)contentURL
{
    return [[self alloc] initWithURL:contentURL videoType:SGVideoTypeNormal];
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        self.contentURL = contentURL;
        self.videoType = videoType;
        self.playableBufferInterval = 2.f;
        [self setupPlayer];
    }
    return self;
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [self.view pause];
    
    switch (self.abstractPlayer.backgroundMode) {
        case SGPlayerBackgroundModeAutoPlayAndPause:
        {
            [self setAutoPlayIfNeed];
        }
            break;
        default:
            break;
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    [self.view resume];
    
    switch (self.abstractPlayer.backgroundMode) {
        case SGPlayerBackgroundModeAutoPlayAndPause:
        {
            [self autoPlayIfNeed];
        }
            break;
        default:
            break;
    }
}

- (void)replaceVideoWithURL:(NSURL *)contentURL
{
    [self replaceVideoWithURL:contentURL videoType:SGVideoTypeNormal];
}

- (void)replaceVideoWithURL:(NSURL *)contentURL videoType:(SGVideoType)videoType
{
    self.contentURL = contentURL;
    self.videoType = videoType;
    [self setupPlayer];
}

#pragma mark - play control

- (void)play
{
    if (self.state == SGPlayerStateFailed || self.state == SGPlayerStateFinished) {
        [self clearPlayer];
    }
    
    [self trySetupPlayer];
    
    switch (self.state) {
        case SGPlayerStateNone:
            self.state = SGPlayerStateBuffering;
            break;
        case SGPlayerStateSuspend:
        case SGPlayerStateReadyToPlay:
            self.state = SGPlayerStatePlaying;
        default:
            break;
    }
    
    [self.avPlayer play];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        switch (self.state) {
            case SGPlayerStateBuffering:
            case SGPlayerStatePlaying:
            case SGPlayerStateReadyToPlay:
                [self.avPlayer play];
            default:
                break;
        }
    });
}

- (void)setAutoPlayIfNeed
{
    switch (self.state) {
        case SGPlayerStatePlaying:
        case SGPlayerStateBuffering:
            self.state = SGPlayerStateSuspend;
            self.autoNeedPlay = YES;
            [self pause];
            break;
        default:
            break;
    }
}

- (void)cancelAutoPlayIfNeed
{
    if (self.autoNeedPlay) {
        self.autoNeedPlay = NO;
    }
}

- (void)autoPlayIfNeed
{
    if (self.autoNeedPlay) {
        [self play];
        self.autoNeedPlay = NO;
    }
}

- (void)setPlayIfNeed
{
    switch (self.state) {
        case SGPlayerStatePlaying:
            self.state = SGPlayerStateBuffering;
        case SGPlayerStateBuffering:
            self.needPlay = YES;
            [self.avPlayer pause];
            break;
        default:
            break;
    }
}

- (void)cancelPlayIfNeed
{
    if (self.needPlay) {
        self.needPlay = NO;
    }
}

- (void)playIfNeed
{
    if (self.needPlay) {
        self.state = SGPlayerStatePlaying;
        [self.avPlayer play];
        self.needPlay = NO;
    }
}

- (void)pause
{
    if (self.state == SGPlayerStateFailed) return;
    self.state = SGPlayerStateSuspend;
    [self cancelPlayIfNeed];
    [self.avPlayer pause];
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completeHandler:nil];
}

- (void)seekToTime:(NSTimeInterval)time completeHandler:(void (^)(BOOL))completeHandler
{
    if (self.avPlayerItem.status != AVPlayerItemStatusReadyToPlay) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setPlayIfNeed];
        self.seeking = YES;
        SGWeakSelf
        [self.avPlayerItem seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.seeking = NO;
                [weakSelf playIfNeed];
                if (completeHandler) {
                    completeHandler(finished);
                }
                SGPlayerLog(@"SGAVPlayer seek success");
            });
        }];
    });
}

- (void)stop
{
    [self clearPlayer];
    self.contentURL = nil;
    self.videoType = SGVideoTypeNormal;
}

- (NSTimeInterval)progress
{
    return CMTimeGetSeconds(self.avPlayerItem.currentTime);
}

- (NSTimeInterval)duration
{
    return CMTimeGetSeconds(self.avPlayerItem.duration);
}

#pragma mark - Setter/Getter

- (void)setState:(SGPlayerState)state
{
    if (_state != state) {
        SGPlayerState temp = _state;
        _state = state;
        [SGNotification postPlayer:self.abstractPlayer statePrevious:temp current:_state];
    }
}

- (void)setContentURL:(NSURL *)contentURL
{
    _contentURL = contentURL;
}

- (void)setVideoType:(SGVideoType)videoType
{
    _videoType = videoType;
}

- (void)setSeeking:(BOOL)seeking
{
    _seeking = seeking;
}

- (void)setDisplayMode:(SGDisplayMode)displayMode
{
    _displayMode = displayMode;
    [self.view setDisplayModeForSGAVGLView:displayMode];
}

- (void)setVolume:(CGFloat)volume
{
    self.avPlayer.volume = volume;
}

- (CGFloat)volume
{
    return self.avPlayer.volume;
}

- (void)setAvPlayer:(AVPlayer *)avPlayer
{
    if (_avPlayer != avPlayer) {
        if (self.playBackTimeObserver) {
            [_avPlayer removeTimeObserver:self.playBackTimeObserver];
            self.playBackTimeObserver = nil;
        }
        _avPlayer = avPlayer;
        
        if ([UIDevice currentDevice].systemVersion.floatValue >= 10.0) {
            _avPlayer.automaticallyWaitsToMinimizeStalling = NO;
        }
        
        if (_avPlayer) {
            SGWeakSelf
            self.playBackTimeObserver = [_avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
                if (weakSelf.state == SGPlayerStatePlaying) {
                    CGFloat current = CMTimeGetSeconds(time);
                    CGFloat duration = weakSelf.duration;
                    [SGNotification postPlayer:weakSelf.abstractPlayer progressPercent:@(current/duration) current:@(current) total:@(duration)];
                }
            }];
        }
    }
}

- (void)setAvPlayerItem:(AVPlayerItem *)avPlayerItem
{
    if (_avPlayerItem != avPlayerItem) {
        [_avPlayerItem removeObserver:self forKeyPath:@"status"];
        [_avPlayerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [_avPlayerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [_avPlayerItem removeOutput:self.avOutput];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_avPlayerItem];
        _avPlayerItem = avPlayerItem;
        if (_avPlayerItem) {
            [_avPlayerItem addObserver:self forKeyPath:@"status" options:0 context:NULL];
            [_avPlayerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:NULL];
            [_avPlayerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:NULL];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(avplayerItemDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_avPlayerItem];
        }
    }
}

- (void)avplayerItemDidPlayToEnd:(NSNotification *)notification
{
    self.state = SGPlayerStateFinished;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (object == self.avPlayerItem) {
            if ([keyPath isEqualToString:@"status"])
            {
                switch (self.avPlayerItem.status) {
                    case AVPlayerItemStatusUnknown:
                    {
                        self.state = SGPlayerStateBuffering;
                        SGPlayerLog(@"SGAVPlayer item status unknown");
                    }
                        break;
                    case AVPlayerItemStatusReadyToPlay:
                    {
                        SGPlayerLog(@"SGAVPlayer item status ready to play");
                        self.readyToPlayTime = [NSDate date].timeIntervalSince1970;
                        switch (self.state) {
                            case SGPlayerStateBuffering:
                                self.state = SGPlayerStatePlaying;
                            case SGPlayerStatePlaying:
                                [self playIfNeed];
                                break;
                            case SGPlayerStateSuspend:
                            case SGPlayerStateFinished:
                            case SGPlayerStateFailed:
                                break;
                            default:
                                self.state = SGPlayerStateReadyToPlay;
                                break;
                        }
                    }
                        break;
                    case AVPlayerItemStatusFailed:
                    {
                        SGPlayerLog(@"SGAVPlayer item status failed");
                        self.readyToPlayTime = 0;
                        self.state = SGPlayerStateFailed;
                    }
                        break;
                }
            }
            else if ([keyPath isEqualToString:@"playbackBufferEmpty"])
            {
                if (self.avPlayerItem.playbackBufferEmpty) {
                    [self setPlayIfNeed];
                }
            }
            else if ([keyPath isEqualToString:@"loadedTimeRanges"])
            {
                NSTimeInterval playableTime = self.playableTime;
                if (_playableTime != playableTime) {
                    _playableTime = playableTime;
                    CGFloat duration = self.duration;
                    [SGNotification postPlayer:self.abstractPlayer playablePercent:@(playableTime/duration) current:@(playableTime) total:@(duration)];
                }
                
                if ((playableTime - self.progress) > self.playableBufferInterval) {
                    [self playIfNeed];
                }
            }
        }
    });
}

- (NSTimeInterval)playableTime
{
    if (self.avPlayerItem.status == AVPlayerItemStatusReadyToPlay) {
        CMTimeRange range = [self.avPlayerItem.loadedTimeRanges.firstObject CMTimeRangeValue];
        NSTimeInterval start = CMTimeGetSeconds(range.start);
        NSTimeInterval duration = CMTimeGetSeconds(range.duration);
        return (start + duration);
    }
    return 0;
}

- (CGSize)presentationSize
{
    if (self.avPlayerItem) {
        return self.avPlayerItem.presentationSize;
    }
    return CGSizeZero;
}

- (UIView *)view
{
    if (!_view) {
        _view = [[SGAVView alloc] initWithFrame:CGRectZero];
    }
    return _view;
}

- (UIImage *)snapshot
{
    switch (self.videoType) {
        case SGVideoTypeNormal:
        {
            AVAssetImageGenerator * imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.avAsset];
            imageGenerator.appliesPreferredTrackTransform = YES;
            imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
            imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
            
            NSError * error = nil;
            CMTime time = self.avPlayerItem.currentTime;
            CMTime actualTime;
            CGImageRef cgImage = [imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
            UIImage * image = [UIImage imageWithCGImage:cgImage];
            return image;
        }
            break;
        case SGVideoTypeVR:
        {
            return self.view.glViewSnapshot;
        }
            break;
    }
}

- (void)setViewAnimationHidden:(BOOL)viewAnimationHidden
{
    if (_viewAnimationHidden != viewAnimationHidden) {
        _viewAnimationHidden = viewAnimationHidden;
        if ([self.view isKindOfClass:[SGAVView class]]) {
            [self.view setAnimationHiddenForAVPlayerLayer:viewAnimationHidden];
        }
    }
}

- (void)setViewTapBlock:(void (^)())block
{
    self.view.tapActionBlock = block;
}

- (CVPixelBufferRef)sgav_glViewPixelBufferToDraw:(SGAVGLView *)glView
{
    if (self.seeking) return nil;
    
    BOOL hasNewPixelBuffer = [self.avOutput hasNewPixelBufferForItemTime:self.avPlayerItem.currentTime];
    if (!hasNewPixelBuffer) {
        if (self.hasPixelBuffer) return nil;
        [self trySetupOutput];
        return nil;
    }
    
    CVPixelBufferRef pixelBuffer = [self.avOutput copyPixelBufferForItemTime:self.avPlayerItem.currentTime itemTimeForDisplay:nil];
    if (!pixelBuffer) {
        [self trySetupOutput];
    } else {
        self.hasPixelBuffer = YES;
    }
    return pixelBuffer;
}

- (void)trySetupPlayer
{
    if (!self.avPlayer) {
        [self setupPlayer];
    }
}

- (void)setupPlayer
{
    [self clearPlayer];
    switch (self.videoType) {
        case SGVideoTypeNormal:
        {
            self.avAsset = [AVAsset assetWithURL:self.contentURL];
            self.avPlayerItem = [AVPlayerItem playerItemWithAsset:self.avAsset automaticallyLoadedAssetKeys:[self avAssetloadKeys]];
            self.avPlayer = [AVPlayer playerWithPlayerItem:self.avPlayerItem];
            [self.view setPlayerForAVPlayerLayer:self.avPlayer animationHidden:self.viewAnimationHidden];
        }
            break;
        case SGVideoTypeVR:
        {
            self.avAsset = [AVAsset assetWithURL:self.contentURL];
            self.avPlayerItem = [AVPlayerItem playerItemWithAsset:self.avAsset];
            self.avPlayer = [AVPlayer playerWithPlayerItem:self.avPlayerItem];
            [self.view setPlayerForSGAVGLView:self.avPlayer dataSource:self displayMode:self.displayMode];
            SGWeakSelf
            [self.avAsset loadValuesAsynchronouslyForKeys:[self avAssetloadKeys] completionHandler:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    for (NSString * loadKey in [weakSelf avAssetloadKeys]) {
                        NSError * error = nil;
                        AVKeyValueStatus keyStatus = [weakSelf.avAsset statusOfValueForKey:loadKey error:&error];
                        if (keyStatus == AVKeyValueStatusFailed) {
                            [weakSelf avAssetPrepareFailed:error];
                            SGPlayerLog(@"AVAsset load failed");
                            return;
                        }
                    }
                    NSError * error = nil;
                    AVKeyValueStatus trackStatus = [weakSelf.avAsset statusOfValueForKey:@"tracks" error:&error];
                    if (trackStatus == AVKeyValueStatusLoaded) {
                        [weakSelf setupOutput];
                    } else {
                        SGPlayerLog(@"AVAsset load failed");
                    }
                });
            }];
        }
            break;
    }
}

- (void)trySetupOutput
{
    BOOL isReadyToPlay = self.avPlayerItem.status == AVPlayerStatusReadyToPlay && self.readyToPlayTime > 10 && (([NSDate date].timeIntervalSince1970 - self.readyToPlayTime) > 0.3);
    if (isReadyToPlay) {
        [self setupOutput];
    }
}

- (void)setupOutput
{
    [self clearOutput];
    
    NSDictionary * pixelBuffer = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
    self.avOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixelBuffer];
    [self.avOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:PixelBufferRequestInterval];
    [self.avPlayerItem addOutput:self.avOutput];
    
    SGPlayerLog(@"SGAVPlayer add output success");
}


- (void)avAssetPrepareFailed:(NSError *)error
{
    
}

- (void)clearPlayer
{
    [SGNotification postPlayer:self.abstractPlayer playablePercent:@(0) current:@(0) total:@(0)];
    [SGNotification postPlayer:self.abstractPlayer progressPercent:@(0) current:@(0) total:@(0)];
    [self clearOutput];
    self.avPlayer = nil;
    self.avPlayerItem = nil;
    self.avAsset = nil;
    [self.view clear];
    self.playBackTimeObserver = nil;
    self.state = SGPlayerStateNone;
    self.needPlay = NO;
    self.seeking = NO;
    _playableTime = 0;
    self.readyToPlayTime = 0;
}

- (void)clearOutput
{
    if (self.avPlayerItem) {
        [self.avPlayerItem removeOutput:self.avOutput];
    }
    self.avOutput = nil;
    self.hasPixelBuffer = NO;
}

- (NSArray <NSString *> *)avAssetloadKeys
{
    return @[@"tracks", @"playable"];
}

- (void)dealloc
{
    SGPlayerLog(@"SGAVPlayer release");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self clearPlayer];
}

@end
