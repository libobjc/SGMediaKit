    //
//  SGFFDecoder.m
//  SGMediaKit
//
//  Created by Single on 05/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFDecoder.h"
#import "SGFFTools.h"
#import "SGAudioManager.h"
#import "SGFFPacketQueue.h"
#import "SGFFFrameQueue.h"
#import "NSDictionary+SGFFmpeg.h"
#import "avformat.h"
#import "swresample.h"
#import "swscale.h"
#import <Accelerate/Accelerate.h>

static AVPacket flush_packet;

@interface SGFFDecoder ()

{
    AVFormatContext * _format_context;
    AVCodecContext * _video_codec;
    AVCodecContext * _audio_codec;
    AVFrame * _video_frame;
    AVFrame * _audio_frame;
    NSTimeInterval _video_timebase;
    NSTimeInterval _audio_timebase;
    
    struct SwsContext * _video_sws_context;
    SwrContext * _audio_swr_context;
    void * _audio_swr_buffer;
    NSUInteger _audio_swr_buffer_size;
}

@property (nonatomic, weak) id <SGFFDecoderDelegate> delegate;
@property (nonatomic, weak) id <SGFFDecoderOutput> output;

@property (nonatomic, strong) NSOperationQueue * ffmpegOperationQueue;
@property (nonatomic, strong) NSInvocationOperation * openFileOperation;
@property (nonatomic, strong) NSInvocationOperation * readPacketOperation;
@property (nonatomic, strong) NSInvocationOperation * decodeFrameOperation;
@property (nonatomic, strong) NSInvocationOperation * displayOperation;

@property (nonatomic, strong) SGFFPacketQueue * audioPacketQueue;
@property (nonatomic, strong) SGFFPacketQueue * videoPacketQueue;
@property (nonatomic, strong) SGFFFrameQueue * videoFrameQueue;

@property (nonatomic, strong) NSError * error;

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, copy, readonly) NSString * contentURLString;
@property (nonatomic, copy) NSDictionary * metadata;
@property (nonatomic, assign) CGSize presentationSize;
@property (nonatomic, assign) NSTimeInterval fps;

@property (atomic, assign) BOOL closed;
@property (atomic, assign) BOOL endOfFile;
@property (atomic, assign) BOOL paused;
@property (atomic, assign) BOOL seeking;
@property (atomic, assign) BOOL reading;
@property (atomic, assign) BOOL decoding;
@property (atomic, assign) BOOL prepareToDecode;

@property (atomic, assign) BOOL videoEnable;
@property (atomic, assign) BOOL audioEnable;

@property (atomic, assign) NSInteger videoStreamIndex;
@property (atomic, assign) NSInteger audioStreamIndex;

@property (nonatomic, copy) NSArray <NSNumber *> * videoStreamIndexs;
@property (nonatomic, copy) NSArray <NSNumber *> * audioStreamIndexs;

@property (nonatomic, assign) NSTimeInterval seekToTime;
@property (nonatomic, copy) void (^seekCompleteHandler)(BOOL finished);

@end

@implementation SGFFDecoder

+ (instancetype)decoderWithContentURL:(NSURL *)contentURL delegate:(id<SGFFDecoderDelegate>)delegate output:(id<SGFFDecoderOutput>)output
{
    return [[self alloc] initWithContentURL:contentURL delegate:delegate output:output];
}

- (instancetype)initWithContentURL:(NSURL *)contentURL delegate:(id<SGFFDecoderDelegate>)delegate output:(id<SGFFDecoderOutput>)output
{
    if (self = [super init]) {
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            av_log_set_callback(sg_ff_log);
            av_register_all();
            avformat_network_init();
            av_init_packet(&flush_packet);
            flush_packet.data = (uint8_t *)&flush_packet;
        });
        
        self.contentURL = contentURL;
        self.delegate = delegate;
        self.output = output;
        
        self.videoStreamIndex = -1;
        self.audioStreamIndex = -1;
        
        [self setupOperationQueue];
    }
    return self;
}

- (void)setupOperationQueue
{
    self.ffmpegOperationQueue = [[NSOperationQueue alloc] init];
    self.ffmpegOperationQueue.maxConcurrentOperationCount = 3;
    self.ffmpegOperationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    
    [self setupOpenFileOperation];
}

- (void)setupOpenFileOperation
{
    self.openFileOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(openFile) object:nil];
    self.openFileOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    self.openFileOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    [self.ffmpegOperationQueue addOperation:self.openFileOperation];
}

- (void)setupReadPacketOperation
{
    if (self.error) {
        [self delegateErrorCallback];
        return;
    }
    
    if (!self.readPacketOperation || self.readPacketOperation.isFinished) {
        self.readPacketOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(readPacketThread) object:nil];
        self.readPacketOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
        self.readPacketOperation.qualityOfService = NSQualityOfServiceUserInteractive;
        [self.readPacketOperation addDependency:self.openFileOperation];
        [self.ffmpegOperationQueue addOperation:self.readPacketOperation];
    }
    
    if (self.videoEnable) {
        if (!self.decodeFrameOperation || self.decodeFrameOperation.isFinished) {
            self.decodeFrameOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(decodeFrameThread) object:nil];
            self.decodeFrameOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
            self.decodeFrameOperation.qualityOfService = NSQualityOfServiceUserInteractive;
            [self.decodeFrameOperation addDependency:self.openFileOperation];
            [self.ffmpegOperationQueue addOperation:self.decodeFrameOperation];
        }
        if (!self.displayOperation || self.displayOperation.isFinished) {
            self.displayOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(displayThread) object:nil];
            self.displayOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
            self.displayOperation.qualityOfService = NSQualityOfServiceUserInteractive;
            [self.displayOperation addDependency:self.openFileOperation];
            [self.ffmpegOperationQueue addOperation:self.displayOperation];
        }
    }
}

#pragma mark - open stream

- (void)openFile
{
    if ([self.delegate respondsToSelector:@selector(decoderWillOpenInputStream:)]) {
        [self.delegate decoderWillOpenInputStream:self];
    }
    // input stream
    self.error = [self openStream];
    if (self.error) {
        [self delegateErrorCallback];
        return;
    } else {
        if ([self.delegate respondsToSelector:@selector(decoderDidOpenInputStream:)]) {
            [self.delegate decoderDidOpenInputStream:self];
        }
    }
    
    // video stream
    NSError * videoError = [self openVideoStreams];
    if (!videoError) {
        if ([self.delegate respondsToSelector:@selector(decoderDidOpenVideoStream:)]) {
            [self.delegate decoderDidOpenVideoStream:self];
        }
    }
    
    // audio stream
    NSError * audioError = [self openAutioStreams];
    if (!audioError) {
        if ([self.delegate respondsToSelector:@selector(decoderDidOpenAudioStream:)]) {
            [self.delegate decoderDidOpenAudioStream:self];
        }
    }
    
    // video and audio error
    if (videoError && audioError) {
        if (videoError.code == SGFFDecoderErrorCodeStreamNotFound && audioError.code != SGFFDecoderErrorCodeStreamNotFound) {
            self.error = audioError;
            [self delegateErrorCallback];
        } else {
            self.error = videoError;
            [self delegateErrorCallback];
        }
        return;
    }
    
    self.prepareToDecode = YES;
    if ([self.delegate respondsToSelector:@selector(decoderDidPrepareToDecodeFrames:)]) {
        [self.delegate decoderDidPrepareToDecodeFrames:self];
    }
    
    [self setupReadPacketOperation];
}

- (NSError *)openStream
{
    _format_context = NULL;
    int reslut = 0;
    NSError * error = nil;
    
    reslut = avformat_open_input(&_format_context, self.contentURLString.UTF8String, NULL, NULL);
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
            avformat_close_input(_format_context);
        }
        return error;
    }
    self.metadata = [NSDictionary sg_dictionaryWithAVDictionary:_format_context->metadata];

    return error;
}

- (NSError *)openVideoStreams
{
    NSError * error = nil;
    self.videoStreamIndexs = [self fetchStreamsForMediaType:AVMEDIA_TYPE_VIDEO];
    
    if (self.videoStreamIndexs.count > 0) {
        for (NSNumber * number in self.videoStreamIndexs) {
            NSInteger index = number.integerValue;
            if ((_format_context->streams[index]->disposition & AV_DISPOSITION_ATTACHED_PIC) == 0) {
                error = [self openVideoStream:index];
                if (!error) {
                    self.videoStreamIndex = index;
                    _video_frame = av_frame_alloc();
                    self.videoEnable = YES;
                    sg_ff_get_AVStream_fps_timebase(_format_context->streams[self.videoStreamIndex], 0.04, &_fps, &_video_timebase);
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

- (NSError *)openVideoStream:(NSInteger)videoStreamIndex
{
    NSError * error = nil;
    AVStream * stream = _format_context->streams[videoStreamIndex];
    
    AVCodec * codec = avcodec_find_decoder(stream->codec->codec_id);
    if (!codec) {
        error = [NSError errorWithDomain:@"video codec not found decoder" code:SGFFDecoderErrorCodeCodecFindDecoder userInfo:nil];
        return error;
    }
    
    int result = avcodec_open2(stream->codec, codec, NULL);
    error = sg_ff_check_error_code(result, SGFFDecoderErrorCodeCodecOpen2);
    if (error) {
        return error;
    }
    
    _video_codec = stream->codec;
    self.presentationSize = CGSizeMake(_video_codec->width, _video_codec->height);
    
    return error;
}

- (NSError *)openAutioStreams
{
    NSError * error = nil;
    self.audioStreamIndexs = [self fetchStreamsForMediaType:AVMEDIA_TYPE_AUDIO];
    
    if (self.audioStreamIndexs.count > 0) {
        for (NSNumber * number in self.audioStreamIndexs) {
            NSInteger index = number.integerValue;
            error = [self openAudioStream:index];
            if (!error) {
                self.audioStreamIndex = index;
                _audio_frame = av_frame_alloc();
                self.audioEnable = YES;
                sg_ff_get_AVStream_fps_timebase(_format_context->streams[self.audioStreamIndex], 0.025, 0, &_audio_timebase);
                break;
            }
        }
    } else {
        error = [NSError errorWithDomain:@"audio stream not found" code:SGFFDecoderErrorCodeStreamNotFound userInfo:nil];
        return error;
    }
    
    return error;
}

- (NSError *)openAudioStream:(NSInteger)audioStreamIndex
{
    NSError * error = nil;
    AVStream * stream = _format_context->streams[audioStreamIndex];
    
    AVCodec * codec = avcodec_find_decoder(stream->codec->codec_id);
    if (!codec) {
        error = [NSError errorWithDomain:@"audio codec not found decoder" code:SGFFDecoderErrorCodeCodecFindDecoder userInfo:nil];
        return error;
    }
    
    int result = avcodec_open2(stream->codec, codec, NULL);
    error = sg_ff_check_error_code(result, SGFFDecoderErrorCodeCodecOpen2);
    if (error) {
        return error;
    }
    
    SGAudioManager * audioManager = [SGAudioManager manager];
    BOOL needSwr = YES;
    if (stream->codec->sample_fmt == AV_SAMPLE_FMT_S16) {
        if (audioManager.samplingRate == stream->codec->sample_rate && audioManager.numOutputChannels == stream->codec->channels) {
            needSwr = NO;
        }
    }
    
    if (needSwr) {
        _audio_swr_context = swr_alloc_set_opts(NULL, av_get_default_channel_layout(audioManager.numOutputChannels), AV_SAMPLE_FMT_S16, audioManager.samplingRate, av_get_default_channel_layout(stream->codec->channels), stream->codec->sample_fmt, stream->codec->sample_rate, 0, NULL);
        
        result = swr_init(_audio_swr_context);
        error = sg_ff_check_error_code(result, SGFFDecoderErrorCodeAuidoSwrInit);
        if (error || !_audio_swr_context) {
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

#pragma mark - Thread

- (void)readPacketThread
{
    if (self.videoEnable) {
        if (self.videoPacketQueue) {
            [self.videoPacketQueue flush];
        } else {
            self.videoPacketQueue = [SGFFPacketQueue packetQueue];
        }
    }
    if (self.audioEnable) {
        if (self.audioPacketQueue) {
            [self.audioPacketQueue flush];
        } else {
            self.audioPacketQueue = [SGFFPacketQueue packetQueue];
        }
    }
    
    self.reading = YES;
    BOOL finished = NO;
    AVPacket packet;
    while (!finished) {
        if (self.closed) {
            NSLog(@"读线程退出");
            break;
        }
        if (self.seeking) {
            self.endOfFile = NO;
            if (self.videoEnable) {
                int64_t ts = (int64_t)(self.seekToTime / _video_timebase);
                avformat_seek_file(_format_context, self.videoStreamIndex, ts, ts, ts, AVSEEK_FLAG_FRAME);
            }
            if (self.audioEnable) {
                int64_t ts = (int64_t)(self.seekToTime / _audio_timebase);
                avformat_seek_file(_format_context, self.audioStreamIndex, ts, ts, ts, AVSEEK_FLAG_FRAME);
            }
            [self.videoPacketQueue flush];
            [self.audioPacketQueue flush];
            [self.videoFrameQueue flush];
            [self.videoPacketQueue putPacket:flush_packet];
            [self.audioPacketQueue putPacket:flush_packet];
            if (self.seekCompleteHandler) {
                self.seekCompleteHandler(YES);
            }
            self.seekToTime = 0;
            self.seekCompleteHandler = nil;
            self.seeking = NO;
            continue;
        }
        if (self.audioPacketQueue.size + self.videoPacketQueue.size >= [SGFFPacketQueue maxCommonSize]) {
            NSTimeInterval interval = 0;
            if (self.paused) {
                interval = [SGFFPacketQueue sleepTimeIntervalForFullAndPaused];
            } else {
                interval = [SGFFPacketQueue sleepTimeIntervalForFull];
            }
            NSLog(@"read thread sleep : %f", interval);
            [NSThread sleepForTimeInterval:interval];
            continue;
        }
        int result = av_read_frame(self->_format_context, &packet);
        if (result < 0) {
            NSLog(@"读取完成");
            self.endOfFile = YES;
            finished = YES;
            if ([self.delegate respondsToSelector:@selector(decoderDidEndOfFile:)]) {
                [self.delegate decoderDidEndOfFile:self];
            }
            break;
        }
        if (packet.stream_index == self.videoStreamIndex) {
            NSLog(@"video : put packet");
            [self.videoPacketQueue putPacket:packet];
            NSLog(@"audio : put packet");
        } else if (packet.stream_index == self.audioStreamIndex) {
            [self.audioPacketQueue putPacket:packet];
        }
    }
    self.reading = NO;
}

- (void)decodeFrameThread
{
    if (self.videoFrameQueue) {
        [self.videoFrameQueue flush];
    } else {
        self.videoFrameQueue = [SGFFFrameQueue frameQueue];
    }
    
    self.decoding = YES;
    BOOL finished = NO;
    AVPacket packet;
    while (!finished) {
        if (self.closed) {
            NSLog(@"解线程退出");
            break;
        }
        if (self.seeking) {
            [NSThread sleepForTimeInterval:0.01];
            continue;
        }
        if (self.endOfFile && self.videoPacketQueue.count == 0) {
            break;
        }
        if (self.videoFrameQueue.duration >= [SGFFFrameQueue maxVideoDuration]) {
            NSTimeInterval interval = 0;
            if (self.paused) {
                interval = [SGFFFrameQueue sleepTimeIntervalForFullAndPaused];
            } else {
                interval = [SGFFFrameQueue sleepTimeIntervalForFull];
            }
            NSLog(@"decode thread sleep : %f", interval);
            [NSThread sleepForTimeInterval:interval];
            continue;
        }
        SGFFVideoFrame * videoFrame = [self getVideoFrameFromPacketQueue];
        if (videoFrame) {
            [self.videoFrameQueue putFrame:videoFrame];
        }
    }
    self.decoding = NO;
}

- (void)displayThread
{
    while (1) {
        if (self.closed) {
            NSLog(@"显线程退出");
            break;
        }
        if (self.seeking || self.paused) {
            [NSThread sleepForTimeInterval:0.01];
            continue;
        }
        if (self.endOfFile && self.audioPacketQueue.count == 0 && self.videoPacketQueue.count == 0 && self.videoFrameQueue.count == 0) {
            break;
        }
        SGFFVideoFrame * videoFrame = [self.videoFrameQueue getFrame];
        if (videoFrame) {
            if ([self.output respondsToSelector:@selector(decoder:renderVideoFrame:)]) {
                [self.output decoder:self renderVideoFrame:videoFrame];
            }
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
    }
}

- (void)pause
{
    self.paused = YES;
}

- (void)resume
{
    self.paused = NO;
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completeHandler:nil];
}

- (void)seekToTime:(NSTimeInterval)time completeHandler:(void (^)(BOOL finished))completeHandler
{
    if (!self.seekEnable || self.error) {
        if (completeHandler) {
            completeHandler(NO);
        }
        return;
    }
    self.seekToTime = time;
    self.seekCompleteHandler = completeHandler;
    self.seeking = YES;
    
    if (self.endOfFile) {
        [self setupReadPacketOperation];
    }
}

#pragma mark - decode frames

- (SGFFVideoFrame *)fetchVideoFrame
{
    return [self.videoFrameQueue getFrame];
}

- (SGFFVideoFrame *)getVideoFrameFromPacketQueue
{
    SGFFVideoFrame * videoFrame;
    while (!videoFrame) {
        if (self.endOfFile && self.videoPacketQueue.count == 0) {
            break;
        }
        AVPacket packet = [self.videoPacketQueue getPacket];
        if (packet.data == flush_packet.data) {
            NSLog(@"video flush");
            if (self.videoEnable) {
                avcodec_flush_buffers(_video_codec);
            }
            continue;
        }
        if (packet.stream_index != self.videoStreamIndex) return nil;
        int packet_size = packet.size;
        while (packet_size > 0)
        {
            int gotframe = 0;
            int lenght = avcodec_decode_video2(_video_codec, _video_frame, &gotframe, &packet);
            if (lenght < 0) {
                break;
            }
            if (gotframe) {
                videoFrame = [self getVideoFrameFromAVFrame];
                if (videoFrame) {
                    break;
                }
            }
            if (lenght == 0) {
                break;
            }
            packet_size -= lenght;
        }
        av_packet_unref(&packet);
    }
    return videoFrame;
}

- (SGFFVideoFrame *)getVideoFrameFromAVFrame
{
    if (!_video_frame->data[0]) return nil;
    
    SGFFVideoFrame * videoFrame = [[SGFFVideoFrame alloc] initWithAVFrame:_video_frame width:_video_codec->width height:_video_codec->height];
    
    videoFrame.position = av_frame_get_best_effort_timestamp(_video_frame) * _video_timebase;
    
    const int64_t frame_duration = av_frame_get_pkt_duration(_video_frame);
    if (frame_duration) {
        videoFrame.duration = frame_duration * _video_timebase;
        videoFrame.duration += _video_frame->repeat_pict * _video_timebase * 0.5;
    } else {
        videoFrame.duration = 1.0 / self.fps;
    }
    
    return videoFrame;
}

- (SGFFAudioFrame *)fetchAudioFrame
{
    return [self getAudioFrameFromPacketQueue];
}

- (SGFFAudioFrame *)getAudioFrameFromPacketQueue
{
    SGFFAudioFrame * audioFrame;
    while (!audioFrame) {
        if (self.endOfFile && self.audioPacketQueue.count == 0) {
            break;
        }
        AVPacket packet = [self.audioPacketQueue getPacket];
        if (packet.data == flush_packet.data) {
            if (self.audioPacketQueue) {
                avcodec_flush_buffers(_audio_codec);
            }
            continue;
        }
        if (packet.stream_index != self.audioStreamIndex) return nil;
        int packet_size = packet.size;
        while (packet_size > 0)
        {
            int gotframe = 0;
            int lenght = avcodec_decode_audio4(_audio_codec, _audio_frame, &gotframe, &packet);
            if (lenght < 0) {
                break;
            }
            if (gotframe) {
                audioFrame = [self getAudioFrameFromAVFrame];
                if (audioFrame) {
                    break;
                }
            }
            if (lenght == 0) {
                break;
            }
            packet_size -= lenght;
        }
        av_packet_unref(&packet);
    }
    return audioFrame;
}

- (SGFFAudioFrame *)getAudioFrameFromAVFrame
{
    if (!_audio_frame->data[0]) return nil;
    
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
        NSError * error = sg_ff_check_error(numberOfFrames);
        if (error) {
            NSLog(@"audio codec error : %@", error);
            return nil;
        }
        audioDataBuffer = _audio_swr_buffer;
    } else {
        if (_audio_codec->sample_fmt != AV_SAMPLE_FMT_S16) {
            NSLog(@"audio format error");
            return nil;
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
    
    return audioFrame;
}

#pragma mark - close stream

- (void)closeFile
{
    [self closeFileAsync:YES];
}

- (void)closeFileAsync:(BOOL)async
{
    self.closed = YES;
    [self.videoPacketQueue destroy];
    [self.audioPacketQueue destroy];
    [self.videoFrameQueue destroy];
    if (async) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self.ffmpegOperationQueue cancelAllOperations];
            [self.ffmpegOperationQueue waitUntilAllOperationsAreFinished];
            [self closeAudioStream];
            [self closeVideoStream];
            [self closeInputStream];
            [self closeOperation];
        });
    } else {
        [self.ffmpegOperationQueue cancelAllOperations];
        [self.ffmpegOperationQueue waitUntilAllOperationsAreFinished];
        [self closeAudioStream];
        [self closeVideoStream];
        [self closeInputStream];
        [self closeOperation];
    }
}

- (void)closeOperation
{
    self.readPacketOperation = nil;
    self.openFileOperation = nil;
    self.displayOperation = nil;
    self.decodeFrameOperation = nil;
    self.ffmpegOperationQueue = nil;
}

- (void)closeVideoStream
{
    self.videoEnable = NO;
    self.videoStreamIndex = -1;
    
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
    self.audioEnable = NO;
    self.audioStreamIndex = -1;
    
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
    self.audioStreamIndexs = nil;
    self.videoStreamIndexs = nil;
    
    if (_format_context) {
        avformat_close_input(&_format_context);
        _format_context = NULL;
    }
}

#pragma mark - setter/getter

- (NSTimeInterval)duration
{
    if (!_format_context) return 0;
    if (_format_context->duration == AV_NOPTS_VALUE) return MAXFLOAT;
    return (CGFloat)(_format_context->duration) / AV_TIME_BASE;
}

- (BOOL)seekEnable
{
    return self.duration > 0;
}

- (NSString *)contentURLString
{
    if ([self.contentURL isFileURL]) {
        return [self.contentURL path];
    } else {
        return [self.contentURL absoluteString];
    }
}

#pragma mark - delegate callback

- (void)delegateErrorCallback
{
    if (self.error) {
        if ([self.delegate respondsToSelector:@selector(decoder:didError:)]) {
            [self.delegate decoder:self didError:self.error];
        }
    }
}

- (void)dealloc
{
    [self closeFileAsync:NO];
    NSLog(@"SGFFDecoder release");
}

@end
