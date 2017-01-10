//
//  SGFFDecoder.m
//  SGMediaKit
//
//  Created by Single on 05/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFDecoder.h"
#import "SGAudioManager.h"
#import "NSDictionary+SGFFmpeg.h"
#import "avformat.h"
#import "swresample.h"
#import <Accelerate/Accelerate.h>

static NSTimeInterval decode_frames_min_duration = 0.0;

static void SGFFLog(void * context, int level, const char * format, va_list args)
{
//    NSString * message = [[NSString alloc] initWithFormat:[NSString stringWithUTF8String:format] arguments:args];
//    NSLog(@"SGFFLog : %@", message);
}

static NSError * checkErrorCode(int errorCode)
{
    if (errorCode < 0) {
        char * error_string_buffer = malloc(256);
        av_strerror(errorCode, error_string_buffer, 256);
        NSString * error_string = [[NSString alloc] initWithUTF8String:error_string_buffer];
        NSError * error = [NSError errorWithDomain:error_string code:errorCode userInfo:nil];
        return error;
    }
    return nil;
}

static void fetchAVStreamFPSTimeBase(AVStream * stream, NSTimeInterval defaultTimebase, NSTimeInterval * pFPS, NSTimeInterval * pTimebase)
{
    NSTimeInterval fps, timebase;
    
    if (stream->time_base.den && stream->time_base.num) {
        timebase = av_q2d(stream->time_base);
    } else if (stream->codec->time_base.den && stream->codec->time_base.num) {
        timebase = av_q2d(stream->codec->time_base);
    } else {
        timebase = defaultTimebase;
    }

    if (stream->codec->ticks_per_frame != 1) {
        
    }
    
    if (stream->avg_frame_rate.den && stream->avg_frame_rate.num) {
        fps = av_q2d(stream->avg_frame_rate);
    } else if (stream->r_frame_rate.den && stream->r_frame_rate.num) {
        fps = av_q2d(stream->r_frame_rate);
    } else {
        fps = 1.0 / timebase;
    }
    
    if (pFPS) {
        * pFPS = fps;
    }
    
    if (pTimebase) {
        * pTimebase = timebase;
    }
}

@interface SGFFDecoder ()

{
    AVFormatContext * _format_context;
    NSInteger _video_stream_index;
    NSInteger _audio_stream_index;
    AVCodecContext * _video_codec;
    AVCodecContext * _audio_codec;
    AVFrame * _video_frame;
    AVFrame * _audio_frame;
    NSTimeInterval _video_timebase;
    NSTimeInterval _audio_timebase;
    
    SwrContext * _audio_swr_context;
    void * _audio_swr_buffer;
    NSUInteger _audio_swr_buffer_size;
}

@property (nonatomic, weak) id <SGFFDecoderDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegate_queue;
@property (nonatomic, strong) NSOperationQueue * ffmpegQueue;

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, copy, readonly) NSString * contentURLString;
@property (nonatomic, copy) NSDictionary * metadata;
@property (nonatomic, assign) BOOL endOfFile;
@property (nonatomic, assign) BOOL decoding;
@property (nonatomic, assign) NSTimeInterval position;

@property (nonatomic, copy) NSArray <NSNumber *> * video_stream_indexs;
@property (nonatomic, copy) NSArray <NSNumber *> * audio_stream_indexs;

@end

@implementation SGFFDecoder

+ (instancetype)decoderWithContentURL:(NSURL *)contentURL delegate:(id<SGFFDecoderDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    return [[self alloc] initWithContentURL:contentURL delegate:delegate delegateQueue:delegateQueue];
}

- (instancetype)initWithContentURL:(NSURL *)contentURL delegate:(id<SGFFDecoderDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    if (self = [super init]) {
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            av_log_set_callback(SGFFLog);
            av_register_all();
            avformat_network_init();
        });
        
        self.contentURL = contentURL;
        self.delegate = delegate;
        self.delegate_queue = delegateQueue;
        self.ffmpegQueue = [[NSOperationQueue alloc] init];
        self.ffmpegQueue.maxConcurrentOperationCount = 1;
        
        _video_stream_index = -1;
        _audio_stream_index = -1;
        
        [self openFile];
    }
    return self;
}

#pragma mark - open stream

- (NSTimeInterval)duration
{
    if (!_format_context) return 0;
    if (_format_context->duration == AV_NOPTS_VALUE) return MAXFLOAT;
    return (CGFloat)(_format_context->duration) / AV_TIME_BASE;
}

- (void)openFile
{
    NSBlockOperation * operation = [NSBlockOperation blockOperationWithBlock:^{
        
        if ([self.delegate respondsToSelector:@selector(decoderWillOpenInputStream:)]) {
            [self delegateSyncCallback:^{
                [self.delegate decoderWillOpenInputStream:self];
            }];
        }
        NSError * error;
        // input stream
        error = [self openStream];
        if (error) {
            if ([self.delegate respondsToSelector:@selector(decoder:openInputStreamError:)]) {
                [self delegateSyncCallback:^{
                    [self.delegate decoder:self openInputStreamError:error];
                }];
            }
            return;
        } else {
            if ([self.delegate respondsToSelector:@selector(decoderDidOpenInputStream:)]) {
                [self delegateSyncCallback:^{
                    [self.delegate decoderDidOpenInputStream:self];
                }];
            }
        }
        
        // video stream
        error = [self fetchVideoStream];
        if (error) {
            if ([self.delegate respondsToSelector:@selector(decoder:openVideoStreamError:)]) {
                [self delegateSyncCallback:^{
                    [self.delegate decoder:self openVideoStreamError:error];
                }];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(decoderDidOpenVideoStream:)]) {
                [self delegateSyncCallback:^{
                    [self.delegate decoderDidOpenVideoStream:self];
                }];
            }
        }
        
        // audio stream
        error = [self fetchAutioStream];
        if (error) {
            if ([self.delegate respondsToSelector:@selector(decoder:openAudioStreamError:)]) {
                [self delegateSyncCallback:^{
                    [self.delegate decoder:self openAudioStreamError:error];
                }];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(decoderDidOpenAudioStream:)]) {
                [self delegateSyncCallback:^{
                    [self.delegate decoderDidOpenAudioStream:self];
                }];
            }
        }
        
        if ([self.delegate respondsToSelector:@selector(decoderDidPrepareToDecodeFrames:)]) {
            [self delegateSyncCallback:^{
                [self.delegate decoderDidPrepareToDecodeFrames:self];
            }];
        }
    }];
    operation.queuePriority = NSOperationQueuePriorityVeryHigh;
    [self.ffmpegQueue addOperation:operation];
}

- (NSError *)openStream
{
    _format_context = NULL;
    int errorCode = 0;
    NSError * error = nil;
    
    errorCode = avformat_open_input(&_format_context, self.contentURLString.UTF8String, NULL, NULL);
    error = checkErrorCode(errorCode);
    if (error || !_format_context) {
        if (_format_context) {
            avformat_free_context(_format_context);
        }
        return error;
    }
    
    errorCode = avformat_find_stream_info(_format_context, NULL);
    error = checkErrorCode(errorCode);
    if (error || !_format_context) {
        if (_format_context) {
            avformat_close_input(_format_context);
        }
        return error;
    }
    self.metadata = [NSDictionary sg_dictionaryWithAVDictionary:_format_context->metadata];

    return error;
}

- (NSError *)fetchVideoStream
{
    NSError * error = nil;
    self.video_stream_indexs = [self fetchStreamsForMediaType:AVMEDIA_TYPE_VIDEO];
    
    if (self.video_stream_indexs.count > 0) {
        for (NSNumber * number in self.video_stream_indexs) {
            NSInteger index = number.integerValue;
            if ((_format_context->streams[index]->disposition & AV_DISPOSITION_ATTACHED_PIC) == 0) {
                error = [self openVideoStream:index];
                if (!error) {
                    _video_stream_index = index;
                    _video_frame = av_frame_alloc();
                    fetchAVStreamFPSTimeBase(_format_context->streams[_video_stream_index], 0.04, &_fps, &_video_timebase);
                    break;
                }
            }
        }
    } else {
        error = [NSError errorWithDomain:@"video stream not found" code:-1 userInfo:nil];
    }
    
    return error;
}

- (NSError *)openVideoStream:(NSInteger)videoStreamIndex
{
    NSError * error = nil;
    AVStream * stream = _format_context->streams[videoStreamIndex];
    
    AVCodec * codec = avcodec_find_decoder(stream->codec->codec_id);
    if (!codec) {
        error = [NSError errorWithDomain:@"video codec not found" code:-1 userInfo:nil];
        NSLog(@"video codec not found %@", error);
        return error;
    }
    
    int errorCode = avcodec_open2(stream->codec, codec, NULL);
    error = checkErrorCode(errorCode);
    if (error) {
        NSLog(@"avcidec open error %@", error);
        return error;
    }
    
    _video_codec = stream->codec;
    
    return error;
}

- (NSError *)fetchAutioStream
{
    NSError * error = nil;
    self.audio_stream_indexs = [self fetchStreamsForMediaType:AVMEDIA_TYPE_AUDIO];
    
    if (self.audio_stream_indexs.count > 0) {
        for (NSNumber * number in self.audio_stream_indexs) {
            NSInteger index = number.integerValue;
            error = [self openAudioStream:index];
            if (!error) {
                _audio_stream_index = index;
                _audio_frame = av_frame_alloc();
                fetchAVStreamFPSTimeBase(_format_context->streams[_audio_stream_index], 0.025, 0, &_audio_timebase);
                break;
            }
        }
    } else {
        error = [NSError errorWithDomain:@"audio stream not found" code:-1 userInfo:nil];
    }
    
    return error;
}

- (NSError *)openAudioStream:(NSInteger)audioStreamIndex
{
    NSError * error = nil;
    int errorCode = 0;
    AVStream * stream = _format_context->streams[audioStreamIndex];
    
    AVCodec * codec = avcodec_find_decoder(stream->codec->codec_id);
    if (!codec) {
        error = [NSError errorWithDomain:@"audio codec not found" code:-1 userInfo:nil];
        NSLog(@"audio codec not found %@", error);
        return error;
    }
    
    errorCode = avcodec_open2(stream->codec, codec, NULL);
    error = checkErrorCode(errorCode);
    if (error) {
        NSLog(@"avcidec open error %@", error);
        return error;
    }
    
    SGAudioManager * audioManager = [SGAudioManager manager];
    BOOL result = YES;
    if (stream->codec->sample_fmt == AV_SAMPLE_FMT_S16) {
        if (audioManager.samplingRate == stream->codec->sample_rate && audioManager.numOutputChannels == stream->codec->channels) {
            result = NO;
        }
    }
    
    if (result) {
        _audio_swr_context = swr_alloc_set_opts(NULL, av_get_default_channel_layout(audioManager.numOutputChannels), AV_SAMPLE_FMT_S16, audioManager.samplingRate, av_get_default_channel_layout(stream->codec->channels), stream->codec->sample_fmt, stream->codec->sample_rate, 0, NULL);
        
        errorCode = swr_init(_audio_swr_context);
        error = checkErrorCode(errorCode);
        if (error) {
            if (_audio_swr_context) {
                swr_free(&_audio_swr_context);
            }
            avcodec_close(stream->codec);
            return error;
        }
    }
    
    _audio_codec = stream->codec;
    
    return error;
}

- (NSArray *)fetchStreamsForMediaType:(enum AVMediaType)mediaType
{
    NSMutableArray * array = [NSMutableArray array];
    for (NSInteger i = 0; i < _format_context->nb_streams; i++) {
        AVStream * stream = _format_context->streams[i];
        if (stream->codec->codec_type == mediaType) {
            [array addObject:[NSNumber numberWithInteger:i]];
        }
    }
    if (array.count > 0) {
        return array;
    }
    return nil;
}

#pragma mark - decode frames

- (void)decodeFrames
{
    [self decodeFramesWithDuration:decode_frames_min_duration];
}

- (void)decodeFramesWithDuration:(NSTimeInterval)duration
{
    self.decoding = YES;
    
    NSBlockOperation * operation = [NSBlockOperation blockOperationWithBlock:^{
        
        NSMutableArray <SGFFFrame *> * frames = [NSMutableArray array];
        AVPacket packet;
        BOOL finished = NO;
        NSTimeInterval decodeDuration = 0;
        
        while (!finished) {
            int errorCode = av_read_frame(_format_context, &packet);
            NSError * error = checkErrorCode(errorCode);
            if (error) {
                NSLog(@"end of file %d", self.endOfFile);
                self.endOfFile = YES;
                finished = YES;
                if ([self.delegate respondsToSelector:@selector(decoderDidEndOfFile:)]) {
                    [self delegateSyncCallback:^{
                        [self.delegate decoderDidEndOfFile:self];
                    }];
                }
                break;
            }
            
            if (packet.stream_index == _video_stream_index)
            {
                int packet_size = packet.size;
                while (packet_size > 0)
                {
                    int gotframe = 0;
                    int lenght = avcodec_decode_video2(_video_codec, _video_frame, &gotframe, &packet);
                    if (lenght <= 0) break;
                    if (gotframe) {
                        if (!_video_frame->data[0]) break;
#warning video frame
                        SGFFVideoFrame * videoFrame = [[SGFFVideoFrame alloc] init];
                        videoFrame.width = _video_codec->width;
                        videoFrame.height = _video_codec->height;
                        videoFrame.position = av_frame_get_best_effort_timestamp(_video_frame) * _video_timebase;
                        
                        const int64_t frame_duration = av_frame_get_pkt_duration(_video_frame);
                        if (frame_duration) {
                            videoFrame.duration = frame_duration * _video_timebase;
                            videoFrame.duration += _video_frame->repeat_pict * _video_timebase * 0.5;
                        } else {
                            videoFrame.duration = 1.0 / self.fps;
                        }
                        
                        if (videoFrame) {
                            [frames addObject:videoFrame];
                        }
                    }
                    packet_size -= lenght;
                }
            }
            else if (packet.stream_index == _audio_stream_index)
            {
                int packet_size = packet.size;
                while (packet_size > 0)
                {
                    int gotframe = 0;
                    int lenght = avcodec_decode_audio4(_audio_codec, _audio_frame, &gotframe, &packet);
                    if (lenght <= 0) break;
                    if (gotframe) {
                        if (!_audio_frame->data[0]) break;
                        
                        SGAudioManager * audioManager = [SGAudioManager manager];
                        NSInteger numberOfFrames;
                        void * audioDataBuffer;
                        
                        if (_audio_swr_context) {
                            const NSUInteger ratio = MAX(1, audioManager.samplingRate / _audio_codec->sample_rate) * MAX(1, audioManager.numOutputChannels / _audio_codec->channels) * 2;
                            const int buffer_size = av_samples_get_buffer_size(NULL, audioManager.numOutputChannels, _audio_frame->nb_samples * ratio, AV_SAMPLE_FMT_S16, 1);
                            
                            if (!_audio_swr_buffer || _audio_swr_buffer_size < buffer_size) {
                                _audio_swr_buffer_size = buffer_size;
                                _audio_swr_buffer = realloc(_audio_swr_buffer, _audio_swr_buffer_size);
                            }
                            
                            Byte * outyput_buffer[2] = {_audio_swr_buffer, 0};
                            numberOfFrames = swr_convert(_audio_swr_context, outyput_buffer, _audio_frame->nb_samples * ratio, (const uint8_t **)_audio_frame->data, _audio_frame->nb_samples);
                            error = checkErrorCode(numberOfFrames);
                            if (error) {
                                NSLog(@"audio codec error : %@", error);
                                return;
                            }
                            audioDataBuffer = _audio_swr_buffer;
                        } else {
                            if (_audio_codec->sample_fmt != AV_SAMPLE_FMT_S16) {
                                NSLog(@"audio format error");
                                return;
                            }
                            audioDataBuffer = _audio_frame->data[0];
                            numberOfFrames = _audio_frame->nb_samples;
                        }
                        
                        const NSUInteger numberOfElements = numberOfFrames * audioManager.numOutputChannels;
                        NSMutableData *data = [NSMutableData dataWithLength:numberOfElements * sizeof(float)];
                        
                        float scale = 1.0 / (float)INT16_MAX ;
                        vDSP_vflt16((SInt16 *)audioDataBuffer, 1, data.mutableBytes, 1, numberOfElements);
                        vDSP_vsmul(data.mutableBytes, 1, &scale, data.mutableBytes, 1, numberOfElements);
                        
                        SGFFAudioFrame * audioFrame = [[SGFFAudioFrame alloc] init];
                        audioFrame.position = av_frame_get_best_effort_timestamp(_audio_frame) * _audio_timebase;
                        audioFrame.duration = av_frame_get_pkt_duration(_audio_frame) * _audio_timebase;
                        audioFrame.samples = data;
                        
                        if (audioFrame.duration == 0) {
                            audioFrame.duration = audioFrame.samples.length / (sizeof(float) * audioManager.numOutputChannels * audioManager.samplingRate);
                        }
                        
                        if (audioFrame) {
                            [frames addObject:audioFrame];
                            self.position = audioFrame.position;
                            decodeDuration += audioFrame.duration;
                            if (decodeDuration > duration) {
                                finished = YES;
                            }
                        }
                    }
                    packet_size -= lenght;
                }
            }
        }
        
        if ([self.delegate respondsToSelector:@selector(decoder:didDecodeFrames:)]) {
            [self delegateSyncCallback:^{
                [self.delegate decoder:self didDecodeFrames:frames];
            }];
        }
        av_packet_unref(&packet);
        
        self.decoding = NO;
    }];
    operation.queuePriority = NSOperationQueuePriorityVeryHigh;
    [self.ffmpegQueue addOperation:operation];
}

- (void)seekToTime:(NSTimeInterval)time completeHandler:(void (^)(BOOL finished))completeHandler
{
    NSBlockOperation * operation = [NSBlockOperation blockOperationWithBlock:^{
        self.position = time;
        self.endOfFile = NO;
        if (_video_stream_index != -1) {
            int64_t ts = (int64_t)(time / _video_timebase);
            avformat_seek_file(_format_context, _video_stream_index, ts, ts, ts, AVSEEK_FLAG_FRAME);
            avcodec_flush_buffers(_video_codec);
        }
        if (_audio_stream_index != -1) {
            int64_t ts = (int64_t)(time / _audio_timebase);
            avformat_seek_file(_format_context, _audio_stream_index, ts, ts, ts, AVSEEK_FLAG_FRAME);
            avcodec_flush_buffers(_audio_codec);
        }
        if (completeHandler) {
            [self delegateSyncCallback:^{
                if (completeHandler) {
                    completeHandler(YES);
                }
            }];
        }
    }];
    operation.queuePriority = NSOperationQueuePriorityVeryHigh;
    [self.ffmpegQueue addOperation:operation];
}

#pragma mark - close stream

- (void)closeFile
{
    [self closeFileAsync:YES];
}

- (void)closeFileAsync:(BOOL)async
{
    if (async) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self.ffmpegQueue cancelAllOperations];
            [self.ffmpegQueue waitUntilAllOperationsAreFinished];
            [self closeAudioStream];
            [self closeVideoStream];
            [self closeInputStream];
        });
    } else {
        [self.ffmpegQueue cancelAllOperations];
        [self.ffmpegQueue waitUntilAllOperationsAreFinished];
        [self closeAudioStream];
        [self closeVideoStream];
        [self closeInputStream];
    }
}

- (void)closeVideoStream
{
    _video_stream_index = -1;
    
    if (_video_frame) {
        av_free(_video_frame);
        _video_frame = NULL;
    }
    if (_video_codec) {
        avcodec_close(_video_codec);
        _video_codec = NULL;
    }
}

- (void)closeAudioStream
{
    _audio_stream_index = -1;
    
    if (_audio_swr_buffer) {
        free(_audio_swr_buffer);
        _audio_swr_buffer = NULL;
        _audio_swr_buffer_size = 0;
    }
    if (_audio_swr_context) {
        swr_free(&_audio_swr_context);
        _audio_swr_context = NULL;
    }
    if (_audio_frame) {
        av_free(_audio_frame);
        _audio_frame = NULL;
    }
    if (_audio_codec) {
        avcodec_close(_audio_codec);
        _audio_codec = NULL;
    }
}

- (void)closeInputStream
{
    self.audio_stream_indexs = nil;
    self.video_stream_indexs = nil;
    
    if (_format_context) {
        avformat_close_input(&_format_context);
        _format_context = NULL;
    }
}

#pragma mark - setter/getter

- (NSString *)contentURLString
{
    if ([self.contentURL isFileURL]) {
        return [self.contentURL path];
    } else {
        return [self.contentURL absoluteString];
    }
}

- (BOOL)videoEnable
{
    return _video_stream_index != -1;
}

- (BOOL)audioEnable
{
    return _audio_stream_index != -1;
}

#pragma mark - delegate callback

- (void)delegateAsyncCallback:(dispatch_block_t)block
{
    [self delegateCallback:block async:YES];
}

- (void)delegateSyncCallback:(dispatch_block_t)block
{
    [self delegateCallback:block async:NO];
}

- (void)delegateCallback:(dispatch_block_t)block async:(BOOL)async
{
    if (block) {
        dispatch_queue_t queue = self.delegate_queue;
        if (!queue) {
            queue = dispatch_get_main_queue();
        }
        if (async) {
            dispatch_sync(queue, block);
        } else {
            dispatch_sync(queue, block);
        }
    }
}

- (void)delegateErrorCallback:(NSError *)error
{
    if (error) {
        if ([self.delegate respondsToSelector:@selector(decoder:didError:)]) {
            [self delegateAsyncCallback:^{
                [self.delegate decoder:self didError:error];
            }];
        }
    }
}

- (void)dealloc
{
    [self closeFileAsync:NO];
    NSLog(@"SGFFDecoder release");
}

@end
