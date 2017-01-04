//
//  SGFFPlayer.m
//  SGMediaKit
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFPlayer.h"
#import "avformat.h"

@implementation SGFFPlayer

+ (instancetype)player
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            av_register_all();
            avformat_network_init();
        });
    }
    return self;
}

- (void)replaceVideoWithURL:(NSURL *)contentURL
{
    [self replaceVideoWithURL:contentURL videoType:SGVideoTypeNormal];
}

- (void)replaceVideoWithURL:(NSURL *)contentURL videoType:(SGVideoType)videoType
{
    NSLog(@"SGFFPlayer %s", __func__);
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

@end
