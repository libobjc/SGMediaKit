//
//  SGFFPlayer.m
//  SGMediaKit
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFPlayer.h"
#import "SGFFDecoder.h"
#import "SGAudioManager.h"
#import "SGPlayerNotification.h"
#import "SGPlayerMacro.h"
#import "SGPlayer+DisplayView.h"

@interface SGFFPlayer () <SGFFDecoderDelegate, SGFFDecoderAudioOutput, SGAudioManagerDelegate>

@property (nonatomic, strong) NSLock * stateLock;

@property (nonatomic, weak) SGPlayer * abstractPlayer;

@property (nonatomic, strong) SGFFDecoder * decoder;
@property (nonatomic, strong) SGAudioManager * audioManager;

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
        self.stateLock = [[NSLock alloc] init];
        self.audioManager = [SGAudioManager manager];
        [self.audioManager registerAudioSession];
    }
    return self;
}

- (void)play
{
    self.playing = YES;
    [self.decoder resume];
    
    switch (self.state) {
        case SGPlayerStateFinished:
            [self seekToTime:0];
            break;
        case SGPlayerStateNone:
        case SGPlayerStateFailed:
        case SGPlayerStateBuffering:
            self.state = SGPlayerStateBuffering;
            break;
        case SGPlayerStateReadyToPlay:
        case SGPlayerStatePlaying:
        case SGPlayerStateSuspend:
            self.state = SGPlayerStatePlaying;
            break;
    }
}

- (void)pause
{
    self.playing = NO;
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
    [self.stateLock lock];
    if (_state != state) {
        SGPlayerState temp = _state;
        _state = state;
        if (_state != SGPlayerStateFailed) {
            self.abstractPlayer.error = nil;
        }
        if (_state == SGPlayerStatePlaying) {
            [self.audioManager playWithDelegate:self];
        } else {
            [self.audioManager pause];
        }
        [SGPlayerNotification postPlayer:self.abstractPlayer statePrevious:temp current:_state];
    }
    [self.stateLock unlock];
}

- (void)setProgress:(NSTimeInterval)progress
{
    if (_progress != progress) {
        _progress = progress;
        NSTimeInterval duration = self.duration;
        if (_progress <= 0.000001 || _progress == duration) {
            [SGPlayerNotification postPlayer:self.abstractPlayer progressPercent:@(_progress/duration) current:@(_progress) total:@(duration)];
        } else {
            NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
            if (currentTime - self.lastPostProgressTime >= 1) {
                self.lastPostProgressTime = currentTime;
                if (!self.decoder.seekEnable) {
                    duration = _progress;
                }
                [SGPlayerNotification postPlayer:self.abstractPlayer progressPercent:@(_progress/duration) current:@(_progress) total:@(duration)];
            }
        }
    }
}

- (void)setBufferDuration:(NSTimeInterval)bufferDuration
{
    if (_bufferDuration != bufferDuration) {
        if (bufferDuration < 0) {
            bufferDuration = 0;
        }
        _bufferDuration = bufferDuration;
        
        NSTimeInterval playableTtime = self.playableTime;
        NSTimeInterval duration = self.duration;
        if (playableTtime > duration) {
            playableTtime = duration;
        }
        
        if (_bufferDuration == 0 || playableTtime == duration) {
            [SGPlayerNotification postPlayer:self.abstractPlayer playablePercent:@(playableTtime/duration) current:@(playableTtime) total:@(duration)];
        } else if (!self.decoder.endOfFile && self.decoder.seekEnable) {
            NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
            if (currentTime - self.lastPostPlayableTime >= 1) {
                self.lastPostPlayableTime = currentTime;
                [SGPlayerNotification postPlayer:self.abstractPlayer playablePercent:@(playableTtime/duration) current:@(playableTtime) total:@(duration)];
            }
        }
    }
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

- (void)reloadPlayableBufferInterval
{
    self.decoder.minBufferedDruation = self.abstractPlayer.playableBufferInterval;
}

#pragma mark - replace video

- (void)replaceVideo
{
    [self clean];
    if (!self.abstractPlayer.contentURL) return;
    
    self.decoder = [SGFFDecoder decoderWithContentURL:self.abstractPlayer.contentURL delegate:self videoOutput:self.abstractPlayer.displayView audioOutput:self];
    [self reloadVolume];
    [self reloadPlayableBufferInterval];
    
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
    [SGPlayerNotification postPlayer:self.abstractPlayer playablePercent:@(self.playableTime/self.duration) current:@(self.playableTime) total:@(self.duration)];
}

- (void)decoderDidPlaybackFinished:(SGFFDecoder *)decoder
{
    self.state = SGPlayerStateFinished;
}

- (void)decoder:(SGFFDecoder *)decoder didChangeValueOfBuffering:(BOOL)buffering
{
    if (buffering) {
        self.state = SGPlayerStateBuffering;
    } else {
        if (self.playing) {
            self.state = SGPlayerStatePlaying;
        } else {
            self.state = SGPlayerStateSuspend;
        }
    }
}

- (void)decoder:(SGFFDecoder *)decoder didChangeValueOfBufferedDuration:(NSTimeInterval)bufferedDuration
{
    self.bufferDuration = bufferedDuration;
}

- (void)decoder:(SGFFDecoder *)decoder didChangeValueOfProgress:(NSTimeInterval)progress
{
    self.progress = progress;
}

- (void)decoder:(SGFFDecoder *)decoder didError:(NSError *)error
{
    [self errorHandler:error];
}

- (void)errorHandler:(NSError *)error
{
    SGError * obj = [[SGError alloc] init];
    obj.error = error;
    self.abstractPlayer.error = obj;
    self.state = SGPlayerStateFailed;
    [SGPlayerNotification postPlayer:self.abstractPlayer error:obj];
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
    self.bufferDuration = 0;
    self.progress = 0;
    self.lastPostProgressTime = 0;
    self.lastPostPlayableTime = 0;
    [self.abstractPlayer.displayView cleanEmptyBuffer];
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
    [self.audioManager unregisterAudioSession];
    SGPlayerLog(@"SGFFPlayer release");
}

#pragma mark - audio

- (Float64)samplingRate
{
    return self.audioManager.samplingRate;
}

- (UInt32)numberOfChannels
{
    return self.audioManager.numberOfChannels;
}

- (void)audioManager:(SGAudioManager *)audioManager outputData:(float *)outputData numberOfFrames:(UInt32)numberOfFrames numberOfChannels:(UInt32)numberOfChannels
{
    if (!self.playing) {
        memset(outputData, 0, numberOfFrames * numberOfChannels * sizeof(float));
        return;
    }
    
    while (numberOfFrames > 0)
    {
        @autoreleasepool
        {
            if (!self.currentAudioFrameSamples) {
                SGFFAudioFrame * frame = [self.decoder fetchAudioFrame];
                
                if (!frame) {
                    memset(outputData, 0, numberOfFrames * numberOfChannels * sizeof(float));
                    return;
                }
                
                self.currentAudioFramePosition = 0;
                self.currentAudioFrameSamples = frame.samples;
            }
            if (self.currentAudioFrameSamples) {
                const void *bytes = (Byte *)self.currentAudioFrameSamples.bytes + self.currentAudioFramePosition;
                const NSUInteger bytesLeft = (self.currentAudioFrameSamples.length - self.currentAudioFramePosition);
                const NSUInteger frameSizeOf = numberOfChannels * sizeof(float);
                const NSUInteger bytesToCopy = MIN(numberOfFrames * frameSizeOf, bytesLeft);
                const NSUInteger framesToCopy = bytesToCopy / frameSizeOf;
                
                memcpy(outputData, bytes, bytesToCopy);
                numberOfFrames -= framesToCopy;
                outputData += framesToCopy * numberOfChannels;
                
                if (bytesToCopy < bytesLeft) {
                    self.currentAudioFramePosition += bytesToCopy;
                } else {
                    self.currentAudioFrameSamples = nil;
                }
            } else {
                memset(outputData, 0, numberOfFrames * numberOfChannels * sizeof(float));
                break;
            }
        }
    }
}

@end
