//
//  SGFFFormatContext.m
//  SGMediaKit
//
//  Created by Single on 2017/2/17.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGFFFormatContext.h"
#import "SGFFTools.h"

static int ffmpeg_interrupt_callback(void *ctx)
{
    SGFFFormatContext * obj = (__bridge SGFFFormatContext *)ctx;
    return [obj.delegate formatContextNeedInterrupt:obj];
}

@interface SGFFFormatContext ()

@property (nonatomic, copy) NSURL * contentURL;

@property (nonatomic, copy) NSError * error;
@property (nonatomic, copy) NSDictionary * metadata;

@property (nonatomic, assign) BOOL videoEnable;
@property (nonatomic, assign) BOOL audioEnable;

@property (nonatomic, assign) int videoStreamIndex;
@property (nonatomic, assign) int audioStreamIndex;

@property (nonatomic, copy) NSArray <NSNumber *> * videoStreamIndexs;
@property (nonatomic, copy) NSArray <NSNumber *> * audioStreamIndexs;

@property (nonatomic, assign) NSTimeInterval videoTimebase;
@property (nonatomic, assign) NSTimeInterval videoFPS;
@property (nonatomic, assign) CGSize videoPresentationSize;

@property (nonatomic, assign) NSTimeInterval audioTimebase;

@end

@implementation SGFFFormatContext

+ (instancetype)formatContextWithContentURL:(NSURL *)contentURL delegate:(id<SGFFFormatContextDelegate>)delegate
{
    return [[self alloc] initWithContentURL:contentURL delegate:delegate];
}

- (instancetype)initWithContentURL:(NSURL *)contentURL delegate:(id<SGFFFormatContextDelegate>)delegate
{
    if (self = [super init]) {
        self.contentURL = contentURL;
        self.delegate = delegate;
        
        self.videoStreamIndex = -1;
        self.audioStreamIndex = -1;
    }
    return self;
}

- (void)setupSync
{
    self.error = [self openStream];
    if (self.error) return;
    
    NSError * videoError = [self openVideoStreams];
    NSError * audioError = [self openAutioStreams];
    
    if (videoError && audioError) {
        if (videoError.code == SGFFDecoderErrorCodeStreamNotFound && audioError.code != SGFFDecoderErrorCodeStreamNotFound) {
            self.error = audioError;
        } else {
            self.error = videoError;
        }
        return;
    }
}

- (NSError *)openStream
{
    int reslut = 0;
    NSError * error = nil;
    
    self->_format_context = avformat_alloc_context();
    if (!_format_context) {
        reslut = -1;
        error = [NSError errorWithDomain:@"SGFFDecoderErrorCodeFormatCreate error" code:SGFFDecoderErrorCodeFormatCreate userInfo:nil];
        return error;
    }
    
    _format_context->interrupt_callback.callback = ffmpeg_interrupt_callback;
    _format_context->interrupt_callback.opaque = (__bridge void *)self;
    
    reslut = avformat_open_input(&_format_context, [self contentURLString].UTF8String, NULL, NULL);
    error = sg_ff_check_error_code(reslut, SGFFDecoderErrorCodeFormatOpenInput);
    if (error || !_format_context) {
        if (_format_context) {
            avformat_free_context(_format_context);
        }
        return error;
    }
    
    reslut = avformat_find_stream_info(_format_context, NULL);
    error = sg_ff_check_error_code(reslut, SGFFDecoderErrorCodeFormatFindStreamInfo);
    if (error || !_format_context) {
        if (_format_context) {
            avformat_close_input(&_format_context);
        }
        return error;
    }
    self.metadata = sg_ff_dict_conver(_format_context->metadata);
    
    return error;
}

- (NSError *)openVideoStreams
{
    NSError * error = nil;
    self.videoStreamIndexs = [self fetchStreamsForMediaType:AVMEDIA_TYPE_VIDEO];
    
    if (self.videoStreamIndexs.count > 0) {
        for (NSNumber * number in self.videoStreamIndexs) {
            int index = number.intValue;
            if ((_format_context->streams[index]->disposition & AV_DISPOSITION_ATTACHED_PIC) == 0) {
                AVCodecContext * codec_context;
                error = [self openVideoStream:index codecContext:&codec_context];
                if (!error) {
                    self.videoStreamIndex = index;
                    self.videoEnable = YES;
                    self.videoTimebase = sg_ff_get_timebase(_format_context->streams[self.videoStreamIndex], 0.00004);
                    self.videoFPS = sg_ff_get_fps(_format_context->streams[self.videoStreamIndex], self.videoTimebase);
                    self.videoPresentationSize = CGSizeMake(codec_context->width, codec_context->height);
                    self->_video_codec_context = codec_context;
                    break;
                }
            }
        }
    } else {
        error = [NSError errorWithDomain:@"video stream not found" code:SGFFDecoderErrorCodeStreamNotFound userInfo:nil];
        return error;
    }
    
    return error;
}

- (NSError *)openVideoStream:(NSInteger)videoStreamIndex codecContext:(AVCodecContext **)codecContext
{
    int result = 0;
    NSError * error = nil;
    AVStream * stream = _format_context->streams[videoStreamIndex];
    
    AVCodecContext * codec_context = avcodec_alloc_context3(NULL);
    if (!codec_context) {
        error = [NSError errorWithDomain:@"video codec context create error" code:SGFFDecoderErrorCodeCodecContextCreate userInfo:nil];
        return error;
    }
    
    result = avcodec_parameters_to_context(codec_context, stream->codecpar);
    error = sg_ff_check_error_code(result, SGFFDecoderErrorCodeCodecContextSetParam);
    if (error) {
        avcodec_free_context(&codec_context);
        return error;
    }
    av_codec_set_pkt_timebase(codec_context, stream->time_base);
    
    AVCodec * codec = avcodec_find_decoder(codec_context->codec_id);
    if (!codec) {
        avcodec_free_context(&codec_context);
        error = [NSError errorWithDomain:@"video codec not found decoder" code:SGFFDecoderErrorCodeCodecFindDecoder userInfo:nil];
        return error;
    }
    codec_context->codec_id = codec->id;
    
    result = avcodec_open2(codec_context, codec, NULL);
    error = sg_ff_check_error_code(result, SGFFDecoderErrorCodeCodecOpen2);
    if (error) {
        avcodec_free_context(&codec_context);
        return error;
    }
    
    * codecContext = codec_context;
    
    return error;
}

- (NSError *)openAutioStreams
{
    NSError * error = nil;
    self.audioStreamIndexs = [self fetchStreamsForMediaType:AVMEDIA_TYPE_AUDIO];
    
    if (self.audioStreamIndexs.count > 0) {
        for (NSNumber * number in self.audioStreamIndexs) {
            int index = number.intValue;
            AVCodecContext * codec_context;
            error = [self openAudioStream:index codecContext:&codec_context];
            if (!error) {
                self.audioStreamIndex = index;
                self.audioEnable = YES;
                self.audioTimebase = sg_ff_get_timebase(_format_context->streams[self.audioStreamIndex], 0.000025);
                self->_audio_codec_context = codec_context;
                break;
            }
        }
    } else {
        error = [NSError errorWithDomain:@"audio stream not found" code:SGFFDecoderErrorCodeStreamNotFound userInfo:nil];
        return error;
    }
    
    return error;
}

- (NSError *)openAudioStream:(NSInteger)audioStreamIndex codecContext:(AVCodecContext **)codecContext
{
    int result = 0;
    NSError * error = nil;
    AVStream * stream = _format_context->streams[audioStreamIndex];
    
    AVCodecContext * codec_context = avcodec_alloc_context3(NULL);
    if (!codec_context) {
        error = [NSError errorWithDomain:@"audio codec context create error" code:SGFFDecoderErrorCodeCodecContextCreate userInfo:nil];
        return error;
    }
    
    result = avcodec_parameters_to_context(codec_context, stream->codecpar);
    error = sg_ff_check_error_code(result, SGFFDecoderErrorCodeCodecContextSetParam);
    if (error) {
        avcodec_free_context(&codec_context);
        return error;
    }
    av_codec_set_pkt_timebase(codec_context, stream->time_base);
    
    AVCodec * codec = avcodec_find_decoder(codec_context->codec_id);
    if (!codec) {
        avcodec_free_context(&codec_context);
        error = [NSError errorWithDomain:@"audio codec not found decoder" code:SGFFDecoderErrorCodeCodecFindDecoder userInfo:nil];
        return error;
    }
    codec_context->codec_id = codec->id;
    
    result = avcodec_open2(codec_context, codec, NULL);
    error = sg_ff_check_error_code(result, SGFFDecoderErrorCodeCodecOpen2);
    if (error) {
        avcodec_free_context(&codec_context);
        return error;
    }
    
    * codecContext = codec_context;
    
    return error;
}

- (NSArray *)fetchStreamsForMediaType:(enum AVMediaType)mediaType
{
    NSMutableArray * array = [NSMutableArray array];
    for (NSInteger i = 0; i < _format_context->nb_streams; i++) {
        AVStream * stream = _format_context->streams[i];
        if (stream->codecpar->codec_type == mediaType) {
            [array addObject:[NSNumber numberWithInteger:i]];
        }
    }
    if (array.count > 0) {
        return array;
    }
    return nil;
}

- (void)destroy
{
    self.videoEnable = NO;
    self.videoStreamIndex = -1;
    
    self.audioEnable = NO;
    self.audioStreamIndex = -1;
    
    self.audioStreamIndexs = nil;
    self.videoStreamIndexs = nil;
    
    if (_video_codec_context) {
        avcodec_close(_video_codec_context);
        _video_codec_context = NULL;
    }
    if (_audio_codec_context) {
        avcodec_close(_audio_codec_context);
        _audio_codec_context = NULL;
    }
    if (_format_context) {
        avformat_close_input(&_format_context);
        _format_context = NULL;
    }
}

- (void)seekFile:(NSTimeInterval)time
{
    int64_t ts = av_rescale(time * 1000, AV_TIME_BASE, 1000);
    avformat_seek_file(self->_format_context, -1, ts, ts, ts, 0);
}

- (int)readFrame:(AVPacket *)packet
{
    return av_read_frame(self->_format_context, packet);
}

- (NSTimeInterval)duration
{
    if (!self->_format_context) return 0;
    if (self->_format_context->duration == AV_NOPTS_VALUE) return MAXFLOAT;
    return (CGFloat)(self->_format_context->duration) / AV_TIME_BASE;
}

- (NSTimeInterval)bitrate
{
    if (!self->_format_context) return 0;
    return (self->_format_context->bit_rate / 1000.0f);
}

- (NSString *)contentURLString
{
    if ([self.contentURL isFileURL]) {
        return [self.contentURL path];
    } else {
        return [self.contentURL absoluteString];
    }
}

- (void)dealloc
{
    [self destroy];
    SGPlayerLog(@"SGFFFormatContext release");
}

@end
