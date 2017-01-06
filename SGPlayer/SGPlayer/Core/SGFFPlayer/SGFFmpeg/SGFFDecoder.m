//
//  SGFFDecoder.m
//  SGMediaKit
//
//  Created by Single on 05/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFDecoder.h"
#import "NSDictionary+SGFFmpeg.h"
#import "avformat.h"

static NSTimeInterval decode_frames_min_duration = 0.0;

static void SGFFLog(void * context, int level, const char * format, va_list args)
{
    
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
    AVFrame * _video_frame;
    AVFrame * _audio_frame;
    NSTimeInterval _video_timebase;
    NSTimeInterval _audio_timebase;
}

@property (nonatomic, weak) id <SGFFDecoderDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegate_queue;
@property (nonatomic, strong) dispatch_queue_t ffmpeg_queue;

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
        self.ffmpeg_queue = dispatch_queue_create("sgffdecoder.ffmpeg.queue", DISPATCH_QUEUE_SERIAL);
        
        _video_stream_index = -1;
        _audio_stream_index = -1;
        
        [self openFile];
    }
    return self;
}

#pragma mark - open stream

- (void)openFile
{
    dispatch_async(self.ffmpeg_queue, ^{
        NSError * error;
        
        // input stream
        error = [self openStream];
        if (error) {
            if ([self.delegate respondsToSelector:@selector(decoder:openInputStreamError:)]) {
                [self delegateAsyncCallback:^{
                    [self.delegate decoder:self openInputStreamError:error];
                }];
            }
            return;
        } else {
            if ([self.delegate respondsToSelector:@selector(decoderDidOpenInputStream:)]) {
                [self delegateAsyncCallback:^{
                    [self.delegate decoderDidOpenInputStream:self];
                }];
            }
        }
        
        // video stream
        error = [self fetchVideoStream];
        if (error) {
            if ([self.delegate respondsToSelector:@selector(decoder:openVideoStreamError:)]) {
                [self delegateAsyncCallback:^{
                    [self.delegate decoder:self openVideoStreamError:error];
                }];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(decoderDidOpenVideoStream:)]) {
                [self delegateAsyncCallback:^{
                    [self.delegate decoderDidOpenVideoStream:self];
                }];
            }
        }
        
        // audio stream
        error = [self fetchAutioStream];
        if (error) {
            if ([self.delegate respondsToSelector:@selector(decoder:openAudioStreamError:)]) {
                [self delegateAsyncCallback:^{
                    [self.delegate decoder:self openAudioStreamError:error];
                }];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(decoderDidOpenAudioStream:)]) {
                [self delegateAsyncCallback:^{
                    [self.delegate decoderDidOpenAudioStream:self];
                }];
            }
        }
        
        if ([self.delegate respondsToSelector:@selector(decoderDidPrepareToDecodeFrames:)]) {
            [self delegateAsyncCallback:^{
                [self.delegate decoderDidPrepareToDecodeFrames:self];
            }];
        }
    });
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
    
    AVCodec * codec = avcodec_find_decoder(stream->codecpar->codec_id);
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
    AVStream * stream = _format_context->streams[audioStreamIndex];
    
    AVCodec * codec = avcodec_find_decoder(stream->codecpar->codec_id);
    if (!codec) {
        error = [NSError errorWithDomain:@"audio codec not found" code:-1 userInfo:nil];
        NSLog(@"audio codec not found %@", error);
        return error;
    }
    
    int errorCode = avcodec_open2(stream->codec, codec, NULL);
    error = checkErrorCode(errorCode);
    if (error) {
        NSLog(@"avcidec open error %@", error);
        return error;
    }
    
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

#pragma mark - decode frames

- (void)decodeFrames
{
    [self decodeFramesWithDuration:decode_frames_min_duration];
}

- (void)decodeFramesWithDuration:(NSTimeInterval)duration
{
    self.decoding = YES;
    
    dispatch_async(self.ffmpeg_queue, ^{
        
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
                    [self delegateAsyncCallback:^{
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
                    int lenght = avcodec_decode_video2(_format_context->streams[_video_stream_index]->codec, _video_frame, &gotframe, &packet);
                    if (lenght <= 0) break;
                    if (gotframe) {
                        if (!_video_frame->data[0]) break;
#warning video frame
                        SGFFVideoFrame * videoFrame = [[SGFFVideoFrame alloc] init];
                        videoFrame.width = _format_context->streams[_video_stream_index]->codec->width;
                        videoFrame.height = _format_context->streams[_video_stream_index]->codec->height;
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
                            self.position = videoFrame.position;
                            decodeDuration += videoFrame.duration;
                            if (decodeDuration > duration) {
                                finished = YES;
                            }
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
                    int lenght = avcodec_decode_audio4(_format_context->streams[_audio_stream_index]->codec, _audio_frame, &gotframe, &packet);
                    if (lenght <= 0) break;
                    if (gotframe) {
                        if (!_audio_frame->data[0]) break;
#warning audio frame
                        SGFFAudioFrame * audioFrame = [[SGFFAudioFrame alloc] init];
                        audioFrame.position = av_frame_get_best_effort_timestamp(_audio_frame) * _audio_timebase;
                        audioFrame.duration = av_frame_get_pkt_duration(_audio_frame) * _audio_timebase;
                        audioFrame.samples = nil;
                        
                        if (audioFrame.duration == 0) {
//                            audioFrame.duration = audioFrame.samples.length / (sizeof(float) * numChannels * audioManager.samplingRate);
                        }
                        
                        if (audioFrame) {
                            [frames addObject:audioFrame];
                            if (_video_stream_index == -1) {
                                self.position = audioFrame.position;
                                decodeDuration += audioFrame.duration;
                                if (decodeDuration > duration) {
                                    finished = YES;
                                }
                            }
                        }
                    }
                    packet_size -= lenght;
                }
            }
        }
        
        if ([self.delegate respondsToSelector:@selector(decoder:didDecodeFrames:)]) {
            [self delegateAsyncCallback:^{
                [self.delegate decoder:self didDecodeFrames:frames];
            }];
        }
        av_packet_unref(&packet);
        
        self.decoding = NO;
    });
}

#pragma mark - close stream

- (void)closeFile
{
    
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

@end
