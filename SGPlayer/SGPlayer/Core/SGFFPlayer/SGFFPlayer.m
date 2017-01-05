//
//  SGFFPlayer.m
//  SGMediaKit
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFPlayer.h"
#import "NSDictionary+SGFFmpeg.h"
#import "avformat.h"

static void SGFFLog(void * context, int level, const char * format, va_list args)
{
    
}

static NSError * checkErrorCode(int errorCode)
{
    if (errorCode != 0) {
        char * error_string_buffer = malloc(256);
        av_strerror(errorCode, error_string_buffer, 256);
        NSString * error_string = [[NSString alloc] initWithUTF8String:error_string_buffer];
        NSError * error = [NSError errorWithDomain:error_string code:errorCode userInfo:nil];
        return error;
    }
    return nil;
}

@interface SGFFPlayer ()

{
    AVFormatContext * _format_context;
}

- (NSString *)contentURLString;

@end

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
            av_log_set_callback(SGFFLog);
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
    self.contentURL = contentURL;
    self.videoType = videoType;
    [self prepareVideo];
}

- (void)prepareVideo
{
    _format_context = NULL;
    int errorCode = 0;
    NSError * error = nil;
    
    errorCode = avformat_open_input(&_format_context, [self contentURLString].UTF8String, NULL, NULL);
    error = checkErrorCode(errorCode);
    if (error) {
        NSLog(@"%@", error);
        return;
    }
    
    errorCode = avformat_find_stream_info(_format_context, NULL);
    error = checkErrorCode(errorCode);
    if (error) {
        NSLog(@"%@", error);
        return;
    }
    
    NSDictionary * dic = [NSDictionary sg_dictionaryWithAVDictionary:_format_context->metadata];
    NSLog(@"metadata : %@", dic);
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

- (NSString *)contentURLString
{
    if ([self.contentURL isFileURL]) {
        return [self.contentURL path];
    } else {
        return [self.contentURL absoluteString];
    }
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

@end
