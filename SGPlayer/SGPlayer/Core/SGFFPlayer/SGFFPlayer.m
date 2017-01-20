//
//  SGFFPlayer.m
//  SGMediaKit
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFPlayer.h"
#import "SGFFDecoder.h"
#import "KxAudioManager.h"
#import "SGNotification.h"
#import "SGPlayer+DisplayView.h"

@interface SGFFPlayer () <SGFFDecoderDelegate, KxAudioManagerDelegate>

@property (nonatomic, strong) NSLock * lock;

@property (nonatomic, weak) SGPlayer * abstractPlayer;

@property (nonatomic, strong) SGFFDecoder * decoder;

@property (nonatomic, strong) NSData * currentAudioFrameSamples;
@property (nonatomic, assign) NSUInteger currentAudioFramePosition;

@property (nonatomic, assign) SGPlayerState state;
@property (nonatomic, assign) NSTimeInterval progress;
@property (nonatomic, assign) NSTimeInterval bufferDuration;

@property (nonatomic, assign) NSTimeInterval lastPostProgressTime;
@property (nonatomic, assign) NSTimeInterval lastPostPlayableTime;

@property (nonatomic, assign) BOOL playing;

@end

@implementation SGFFPlayer

+ (instancetype)playerWithAbstractPlayer:(SGPlayer *)abstractPlayer
{
    return [[self alloc] initWithAbstractPlayer:abstractPlayer];
}

- (instancetype)initWithAbstractPlayer:(SGPlayer *)abstractPlayer
{
    if (self = [super init]) {
        self.abstractPlayer = abstractPlayer;
        self.lock = [[NSLock alloc] init];
        [[KxAudioManager audioManager] activateAudioSession];
    }
    return self;
}

- (void)play
{
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self.decoder closeFile];
//    });
    
    self.playing = YES;
    [KxAudioManager audioManager].delegate = self;
    [[KxAudioManager audioManager] play];
    [self.decoder resume];
    
    switch (self.state) {
        case SGPlayerStateNone:
        case SGPlayerStateSuspend:
        case SGPlayerStateFailed:
        case SGPlayerStateFinished:
        case SGPlayerStateBuffering:
        {
            self.state = SGPlayerStateBuffering;
        }
            break;
        case SGPlayerStateReadyToPlay:
        case SGPlayerStatePlaying:
            self.state = SGPlayerStatePlaying;
            break;
    }
}

- (void)pause
{
    self.playing = NO;
    [[KxAudioManager audioManager] pause];
    [self.decoder pause];
    
    switch (self.state) {
        case SGPlayerStateNone:
        case SGPlayerStateSuspend:
            break;
        case SGPlayerStateFailed:
        case SGPlayerStateReadyToPlay:
        case SGPlayerStateFinished:
        case SGPlayerStatePlaying:
        case SGPlayerStateBuffering:
        {
            self.state = SGPlayerStateSuspend;
        }
            break;
    }
}

- (void)stop
{
    [self clean];
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self.decoder seekToTime:time];
}

- (void)seekToTime:(NSTimeInterval)time completeHandler:(void (^)(BOOL finished))completeHandler
{
    [self.decoder seekToTime:time completeHandler:completeHandler];
}

- (void)setState:(SGPlayerState)state
{
    [self.lock lock];
    if (_state != state) {
        SGPlayerState temp = _state;
        _state = state;
        [SGNotification postPlayer:self.abstractPlayer statePrevious:temp current:_state];
    }
    [self.lock unlock];
}

- (void)setProgress:(NSTimeInterval)progress
{
    [self.lock lock];
    if (_progress != progress) {
        _progress = progress;
        NSTimeInterval duration = self.duration;
        if (_progress == 0 || _progress == duration) {
            [SGNotification postPlayer:self.abstractPlayer progressPercent:@(_progress/duration) current:@(_progress) total:@(duration)];
        } else {
            NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
            if (currentTime - self.lastPostProgressTime >= 1) {
                self.lastPostProgressTime = currentTime;
                [SGNotification postPlayer:self.abstractPlayer progressPercent:@(_progress/duration) current:@(_progress) total:@(duration)];
            }
        }
    }
    [self.lock unlock];
}

- (void)setBufferDuration:(NSTimeInterval)bufferDuration
{
    [self.lock lock];
    if (_bufferDuration != bufferDuration) {
        if (bufferDuration < 0) {
            bufferDuration = 0;
        }
        _bufferDuration = bufferDuration;
        if (!self.decoder.endOfFile) {
            NSTimeInterval playableTtime = self.playableTime;
            NSTimeInterval duration = self.duration;
            if (playableTtime > duration) {
                playableTtime = duration;
            }
            if (_bufferDuration == 0 || playableTtime == duration) {
                [SGNotification postPlayer:self.abstractPlayer playablePercent:@(playableTtime/duration) current:@(playableTtime) total:@(duration)];
            } else {
                NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
                if (currentTime - self.lastPostPlayableTime >= 1) {
                    self.lastPostPlayableTime = currentTime;
                    [SGNotification postPlayer:self.abstractPlayer playablePercent:@(playableTtime/duration) current:@(playableTtime) total:@(duration)];
                }
            }
        }
    }
    [self.lock unlock];
}

- (NSTimeInterval)playableTime
{
    if (self.decoder.endOfFile) {
        return self.duration;
    }
    return self.progress + self.bufferDuration;
}

- (NSTimeInterval)duration
{
    return self.decoder.duration;
}

- (CGSize)presentationSize
{
    if (self.decoder.prepareToDecode) {
        return self.decoder.presentationSize;
    }
    return CGSizeZero;
}

- (void)reloadVolume
{
    self.decoder.volume = self.abstractPlayer.volume;
}

#pragma mark - replace video

- (void)replaceVideo
{
    [self clean];
    if (!self.abstractPlayer.contentURL) return;
    
    self.decoder = [SGFFDecoder decoderWithContentURL:self.abstractPlayer.contentURL delegate:self output:self.abstractPlayer.displayView];
    [self reloadVolume];
    
    switch (self.abstractPlayer.videoType) {
        case SGVideoTypeNormal:
            self.abstractPlayer.displayView.rendererType = SGDisplayRendererTypeFFmpegPexelBuffer;
            break;
        case SGVideoTypeVR:
            self.abstractPlayer.displayView.rendererType = SGDisplayRendererTypeFFmpegPexelBufferVR;
            break;
    }
}

#pragma mark - SGFFDecoderDelegate

- (void)decoderWillOpenInputStream:(SGFFDecoder *)decoder
{
    self.state = SGPlayerStateBuffering;
}

- (void)decoderDidPrepareToDecodeFrames:(SGFFDecoder *)decoder
{
    self.state = SGPlayerStateReadyToPlay;
}

- (void)decoderDidEndOfFile:(SGFFDecoder *)decoder
{

}

- (void)decoder:(SGFFDecoder *)decoder didChangeValueOfBuffering:(BOOL)buffering
{
    if (buffering) {
        [self pause];
    } else {
        [self play];
    }
}

- (void)decoder:(SGFFDecoder *)decoder didError:(NSError *)error
{
    [self errorHandler:error];
}

- (void)errorHandler:(NSError *)error
{
    self.state = SGPlayerStateFailed;
    [SGNotification postPlayer:self.abstractPlayer error:error];
}

#pragma mark - clean

- (void)clean
{
    [self cleanDecoder];
    [self cleanFrames];
    [self cleanPlayer];
}

- (void)cleanPlayer
{
    self.playing = NO;
    self.state = SGPlayerStateNone;
    self.progress = 0;
    self.lastPostProgressTime = 0;
    self.lastPostPlayableTime = 0;
    [self.abstractPlayer.displayView cleanEmptyBuffer];
//    [[KxAudioManager audioManager] pause];
}

- (void)cleanFrames
{
    self.currentAudioFrameSamples = nil;
    self.currentAudioFramePosition = 0;
}

- (void)cleanDecoder
{
    if (self.decoder) {
        [self.decoder closeFile];
        self.decoder = nil;
    }
}

- (void)dealloc
{
    [self clean];
    NSLog(@"SGFFPlayer release");
}

#pragma mark - audio

- (void)audioManager:(KxAudioManager *)audioManager outputData:(float *)data numberOfFrames:(UInt32)numFrames numberOfChannels:(UInt32)numChannels
{
    if (!self.playing) return;
    
    [self audioCallbackFillData:data numFrames:numFrames numChannels:numChannels];
}

- (void)audioCallbackFillData:(float *)outData numFrames:(UInt32) numFrames numChannels:(UInt32)numChannels
{
    while (numFrames > 0)
    {
        @autoreleasepool
        {
            if (!self.currentAudioFrameSamples) {
                SGFFAudioFrame * frame = [self.decoder fetchAudioFrame];
                
                if (!frame) {
                    memset(outData, 0, numFrames * numChannels * sizeof(float));
                    [[KxAudioManager audioManager] pause];
                    return;
                }
                
                self.currentAudioFramePosition = 0;
                self.currentAudioFrameSamples = frame.samples;
            }
            if (self.currentAudioFrameSamples) {
                const void *bytes = (Byte *)self.currentAudioFrameSamples.bytes + self.currentAudioFramePosition;
                const NSUInteger bytesLeft = (self.currentAudioFrameSamples.length - self.currentAudioFramePosition);
                const NSUInteger frameSizeOf = numChannels * sizeof(float);
                const NSUInteger bytesToCopy = MIN(numFrames * frameSizeOf, bytesLeft);
                const NSUInteger framesToCopy = bytesToCopy / frameSizeOf;
                
                memcpy(outData, bytes, bytesToCopy);
                numFrames -= framesToCopy;
                outData += framesToCopy * numChannels;
                
                if (bytesToCopy < bytesLeft) {
                    self.currentAudioFramePosition += bytesToCopy;
                } else {
                    self.currentAudioFrameSamples = nil;
                }
            } else {
                memset(outData, 0, numFrames * numChannels * sizeof(float));
                break;
            }
        }
    }
}

@end
