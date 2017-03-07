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

@property (nonatomic, strong) SGFFTrack * videoTrack;
@property (nonatomic, strong) SGFFTrack * audioTrack;

@property (nonatomic, strong) NSArray <SGFFTrack *> * videoTracks;
@property (nonatomic, strong) NSArray <SGFFTrack *> * audioTracks;

@property (nonatomic, assign) NSTimeInterval videoTimebase;
@property (nonatomic, assign) NSTimeInterval videoFPS;
@property (nonatomic, assign) CGSize videoPresentationSize;
@property (nonatomic, assign) CGFloat videoAspect;

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
        
        self.videoTrack = nil;
        self.audioTrack = nil;
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
    error = SGFFCheckErrorCode(reslut, SGFFDecoderErrorCodeFormatOpenInput);
    if (error || !_format_context) {
        if (_format_context) {
            avformat_free_context(_format_context);
        }
        return error;
    }
    
    reslut = avformat_find_stream_info(_format_context, NULL);
    error = SGFFCheckErrorCode(reslut, SGFFDecoderErrorCodeFormatFindStreamInfo);
    if (error || !_format_context) {
        if (_format_context) {
            avformat_close_input(&_format_context);
        }
        return error;
    }
    self.metadata = SGFFFoundationBrigeOfAVDictionary(_format_context->metadata);
    
    return error;
}

- (NSError *)openVideoStreams
{
    NSError * error = nil;
    self.videoTracks = [self fetchStreamsForMediaType:AVMEDIA_TYPE_VIDEO];
    
    if (self.videoTracks.count > 0) {
        for (SGFFTrack * obj in self.videoTracks) {
            int index = obj.index;
            if ((_format_context->streams[index]->disposition & AV_DISPOSITION_ATTACHED_PIC) == 0) {
                AVCodecContext * codec_context;
                error = [self openVideoStream:index codecContext:&codec_context];
                if (!error) {
                    self.videoTrack = obj;
                    self.videoEnable = YES;
                    self.videoTimebase = SGFFStreamGetTimebase(_format_context->streams[index], 0.00004);
                    self.videoFPS = SGFFStreamGetFPS(_format_context->streams[index], self.videoTimebase);
                    self.videoPresentationSize = CGSizeMake(codec_context->width, codec_context->height);
                    self.videoAspect = (CGFloat)codec_context->width / (CGFloat)codec_context->height;
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
    error = SGFFCheckErrorCode(result, SGFFDecoderErrorCodeCodecContextSetParam);
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
    error = SGFFCheckErrorCode(result, SGFFDecoderErrorCodeCodecOpen2);
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
    self.audioTracks = [self fetchStreamsForMediaType:AVMEDIA_TYPE_AUDIO];
    
    if (self.audioTracks.count > 0) {
        for (SGFFTrack * obj in self.audioTracks) {
            int index = obj.index;
            AVCodecContext * codec_context;
            error = [self openAudioStream:index codecContext:&codec_context];
            if (!error) {
                self.audioTrack = obj;
                self.audioEnable = YES;
                self.audioTimebase = SGFFStreamGetTimebase(_format_context->streams[index], 0.000025);
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
    AVStream * stream = _format_context->streams[2];
    AVCodecContext * codec_context = avcodec_alloc_context3(NULL);
    if (!codec_context) {
        error = [NSError errorWithDomain:@"audio codec context create error" code:SGFFDecoderErrorCodeCodecContextCreate userInfo:nil];
        return error;
    }
    
    result = avcodec_parameters_to_context(codec_context, stream->codecpar);
    error = SGFFCheckErrorCode(result, SGFFDecoderErrorCodeCodecContextSetParam);
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
    error = SGFFCheckErrorCode(result, SGFFDecoderErrorCodeCodecOpen2);
    if (error) {
        avcodec_free_context(&codec_context);
        return error;
    }
    
    * codecContext = codec_context;
    
    return error;
}

- (NSArray <SGFFTrack *> *)fetchStreamsForMediaType:(enum AVMediaType)mediaType
{
    NSMutableArray <SGFFTrack *> * tracks = [NSMutableArray array];
    for (NSInteger i = 0; i < _format_context->nb_streams; i++) {
        AVStream * stream = _format_context->streams[i];
        if (stream->codecpar->codec_type == mediaType) {
            SGFFTrack * track = [[SGFFTrack alloc] init];
            track.index = (int)i;
            [tracks addObject:track];
        }
    }
    if (tracks.count > 0) {
        return tracks;
    }
    return nil;
}

- (void)destroy
{
    self.videoEnable = NO;
    self.videoTrack = nil;
    
    self.audioEnable = NO;
    self.audioTrack = nil;
    
    self.audioTracks = nil;
    self.videoTracks = nil;
    
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
