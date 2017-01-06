//
//  SGFFPlayer.m
//  SGMediaKit
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFPlayer.h"
#import "SGFFDecoder.h"

@interface SGFFPlayer () <SGFFDecoderDelegate>

@property (nonatomic, strong) SGFFDecoder * decoder;
@property (nonatomic, strong) NSTimer * decodeTimer;

@property (nonatomic, strong) NSMutableArray * videoFrames;
@property (nonatomic, strong) NSMutableArray * audioFrames;

@end

@implementation SGFFPlayer

@synthesize view = _view;

+ (instancetype)player
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
        [self setupFrames];
        [self setupDecodeTimer];
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
    self.videoType = videoType;
    [self setupDecoder];
}

- (void)play
{
    NSLog(@"SGFFPlayer %s", __func__);
}

- (void)stop
{
    NSLog(@"SGFFPlayer %s", __func__);
}

- (void)pause
{
    NSLog(@"SGFFPlayer %s", __func__);
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completeHandler:nil];
}

- (void)seekToTime:(NSTimeInterval)time completeHandler:(void (^)(BOOL))completeHandler
{
    NSLog(@"SGFFPlayer %s", __func__);
}

- (void)setVolume:(CGFloat)volume
{
    NSLog(@"SGFFPlayer %s", __func__);
}

- (void)setViewTapBlock:(void (^)())block
{
    NSLog(@"SGFFPlayer %s", __func__);
}

- (UIImage *)snapshot
{
    NSLog(@"SGFFPlayer %s", __func__);
    return nil;
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

#pragma mark - frames

- (void)setupFrames
{
    [self cleanFrames];
    self.videoFrames = [NSMutableArray array];
    self.audioFrames = [NSMutableArray array];
}

- (void)addFrames:(NSArray <SGFFFrame *> *)frames
{
    for (SGFFFrame * frame in frames) {
        switch (frame.type) {
            case SGFFFrameTypeVideo:
            {
                [self.videoFrames addObject:frame];
            }
                break;
            case SGFFFrameTypeAudio:
            {
                [self.audioFrames addObject:frame];
            }
                break;
            default:
                break;
        }
    }
    NSLog(@"\nvideo frame count : %ld\naudio frame count : %ld", self.videoFrames.count, self.audioFrames.count);
}

#pragma mark - decode frames

- (void)setupDecoder
{
    [self cleanDecoder];
    self.decoder = [SGFFDecoder decoderWithContentURL:self.contentURL delegate:self delegateQueue:dispatch_get_main_queue()];
}

- (void)setupDecodeTimer
{
    self.decodeTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(decodeTimerHandler) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.decodeTimer forMode:NSRunLoopCommonModes];
    [self pauseDecodeTimer];
}

- (void)pauseDecodeTimer
{
    self.decodeTimer.fireDate = [NSDate distantFuture];
}

- (void)resumeDecodeTimer
{
    self.decodeTimer.fireDate = [NSDate distantPast];
}

- (void)decodeTimerHandler
{
    if (!self.decoder.endOfFile && !self.decoder.decoding) {
        [self.decoder decodeFrames];
    }
}

#pragma mark - clean

- (void)cleanDecoder
{
    if (self.decoder) {
        [self.decoder closeFile];
        self.decoder = nil;
    }
    [self pauseDecodeTimer];
}

- (void)cleanFrames
{
    [self.videoFrames removeAllObjects];
    [self.audioFrames removeAllObjects];
}

#pragma mark - SGFFDecoderDelegate

- (void)decoderDidOpenInputStream:(SGFFDecoder *)decoder
{
    
    NSLog(@"SGFFPlayer %s \nmetadata : %@", __func__, decoder.metadata);
}

- (void)decoder:(SGFFDecoder *)decoder openInputStreamError:(NSError *)error
{
    NSLog(@"SGFFPlayer %s, \nerror : %@", __func__, error);
}

- (void)decoderDidOpenVideoStream:(SGFFDecoder *)decoder
{
    NSLog(@"SGFFPlayer %s", __func__);
}

- (void)decoder:(SGFFDecoder *)decoder openVideoStreamError:(NSError *)error
{
    NSLog(@"SGFFPlayer %s, \nerror : %@", __func__, error);
    
}

- (void)decoderDidOpenAudioStream:(SGFFDecoder *)decoder
{
    NSLog(@"SGFFPlayer %s", __func__);
}

- (void)decoder:(SGFFDecoder *)decoder openAudioStreamError:(NSError *)error
{
    NSLog(@"SGFFPlayer %s, \nerror : %@", __func__, error);
}

- (void)decoderDidPrepareToDecodeFrames:(SGFFDecoder *)decoder
{
    NSLog(@"SGFFPlayer %s", __func__);
    NSLog(@"\nvideo enable : %d\naudio enable : %d", decoder.videoEnable, decoder.audioEnable);
    [self resumeDecodeTimer];
}

- (void)decoder:(SGFFDecoder *)decoder didDecodeFrames:(NSArray<SGFFFrame *> *)frames
{
    NSLog(@"SGFFPlayer %s \nframes : %@", __func__, frames);
    if (frames.count > 0) {
        [self addFrames:frames];
    }
}

- (void)decoderDidEndOfFile:(SGFFDecoder *)decoder
{
    NSLog(@"SGFFPlayer %s", __func__);
    [self pauseDecodeTimer];
}

- (void)decoder:(SGFFDecoder *)decoder didError:(NSError *)error
{
    NSLog(@"SGFFPlayer %s, \nerror : %@", __func__, error);
}

@end
