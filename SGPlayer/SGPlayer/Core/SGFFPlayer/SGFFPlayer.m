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

- (void)setupDecoder
{
    if (self.decoder) {
        [self.decoder closeFile];
        self.decoder = nil;
    }
    self.decoder = [SGFFDecoder decoderWithContentURL:self.contentURL delegate:self delegateQueue:dispatch_get_main_queue()];
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

#pragma mark - SGFFDecoderDelegate

- (void)decoder:(SGFFDecoder *)decoder didError:(NSError *)error
{
    NSLog(@"decoder error : %@", error);
}

- (void)decoderDidOpenInputStream:(SGFFDecoder *)decoder
{
    NSLog(@"decoder did open input stream");
}

- (void)decoderDidFindStreamInfo:(SGFFDecoder *)decoder
{
    NSLog(@"decoder did find stream info \nmetadata : %@", decoder.metadata);
}

- (void)decoderDidPrepareToDecodeFrames:(SGFFDecoder *)decoder
{
    NSLog(@"decoder did prepare to decode frames");
}

@end
