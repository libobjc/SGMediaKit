    //
//  SGFFDecoder.m
//  SGMediaKit
//
//  Created by Single on 05/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFDecoder.h"
#import "SGFFTools.h"
#import "SGFFPacketQueue.h"
#import "SGFFFrameQueue.h"
#import "avformat.h"
#import "swresample.h"
#import "swscale.h"
#import <Accelerate/Accelerate.h>
#import "SGPlayerMacro.h"

static AVPacket flush_packet;

static int ffmpeg_interrupt_callback(void *ctx)
{
    SGFFDecoder * obj = (__bridge SGFFDecoder *)ctx;
    return obj.closed;
}

@interface SGFFDecoder ()

{
    AVFormatContext * _format_context;
    AVCodecContext * _video_codec;
    AVCodecContext * _audio_codec;
    AVFrame * _video_frame;
    AVFrame * _audio_frame;
    
    struct SwsContext * _video_sws_context;
    SwrContext * _audio_swr_context;
    void * _audio_swr_buffer;
    NSUInteger _audio_swr_buffer_size;
}

@property (nonatomic, weak) id <SGFFDecoderDelegate> delegate;
@property (nonatomic, weak) id <SGFFDecoderVideoOutput> videoOutput;
@property (nonatomic, weak) id <SGFFDecoderAudioOutput> audioOutput;

@property (nonatomic, strong) NSOperationQueue * ffmpegOperationQueue;
@property (nonatomic, strong) NSInvocationOperation * openFileOperation;
@property (nonatomic, strong) NSInvocationOperation * readPacketOperation;
@property (nonatomic, strong) NSInvocationOperation * decodeFrameOperation;
@property (nonatomic, strong) NSInvocationOperation * displayOperation;

@property (nonatomic, strong) SGFFPacketQueue * videoPacketQueue;
@property (nonatomic, strong) SGFFFrameQueue * videoFrameQueue;
@property (nonatomic, strong) SGFFFrameQueue * audioFrameQueue;

@property (nonatomic, strong) NSError * error;

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, copy, readonly) NSString * contentURLString;
@property (nonatomic, copy) NSDictionary * metadata;
@property (nonatomic, assign) CGSize presentationSize;
@property (nonatomic, assign) NSTimeInterval fps;
@property (nonatomic, assign) NSTimeInterval progress;
@property (nonatomic, assign) NSTimeInterval bufferedDuration;

@property (nonatomic, assign) BOOL buffering;

@property (nonatomic, assign) BOOL playbackFinished;
@property (atomic, assign) BOOL closed;
@property (atomic, assign) BOOL endOfFile;
@property (atomic, assign) BOOL paused;
@property (atomic, assign) BOOL seeking;
@property (atomic, assign) BOOL reading;
@property (atomic, assign) BOOL decoding;
@property (atomic, assign) BOOL prepareToDecode;

@property (atomic, assign) BOOL videoEnable;
@property (atomic, assign) BOOL audioEnable;

@property (atomic, assign) int videoStreamIndex;
@property (atomic, assign) int audioStreamIndex;

@property (atomic, assign) NSTimeInterval videoTimebase;
@property (atomic, assign) NSTimeInterval audioTimebase;

@property (nonatomic, copy) NSArray <NSNumber *> * videoStreamIndexs;
@property (nonatomic, copy) NSArray <NSNumber *> * audioStreamIndexs;

@property (nonatomic, assign) NSTimeInterval seekToTime;
@property (nonatomic, copy) void (^seekCompleteHandler)(BOOL finished);

@property (nonatomic, strong) SGFFVideoFrame * currentVideoFrame;
@property (nonatomic, strong) SGFFAudioFrame * currentAudioFrame;

@property (nonatomic, strong) NSLock * clockLock;
@property (nonatomic, assign) NSTimeInterval audioTimeClock;
@property (nonatomic, assign) BOOL needUpdateAudioTimeClock;

@end

@implementation SGFFDecoder

+ (instancetype)decoderWithContentURL:(NSURL *)contentURL delegate:(id<SGFFDecoderDelegate>)delegate videoOutput:(id<SGFFDecoderVideoOutput>)videoOutput audioOutput:(id<SGFFDecoderAudioOutput>)audioOutput
{
    return [[self alloc] initWithContentURL:contentURL delegate:delegate videoOutput:videoOutput audioOutput:audioOutput];
}

- (instancetype)initWithContentURL:(NSURL *)contentURL delegate:(id<SGFFDecoderDelegate>)delegate videoOutput:(id<SGFFDecoderVideoOutput>)videoOutput audioOutput:(id<SGFFDecoderAudioOutput>)audioOutput
{
    if (self = [super init]) {
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            av_log_set_callback(sg_ff_log);
            av_register_all();
            avformat_network_init();
            av_init_packet(&flush_packet);
            flush_packet.data = (uint8_t *)&flush_packet;
            flush_packet.duration = 0;
        });
        
        self.contentURL = contentURL;
        self.delegate = delegate;
        self.videoOutput = videoOutput;
        self.audioOutput = audioOutput;
        
        self.videoStreamIndex = -1;
        self.audioStreamIndex = -1;
        
        [self setupOperationQueue];
    }
    return self;
}

#pragma mark - setup operations

- (void)setupOperationQueue
{
    self.clockLock = [[NSLock alloc] init];
    
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
    int reslut = 0;
    NSError * error = nil;
    
    _format_context = avformat_alloc_context();
    if (!_format_context) {
        reslut = -1;
        error = [NSError errorWithDomain:@"SGFFDecoderErrorCodeFormatCreate error" code:SGFFDecoderErrorCodeFormatCreate userInfo:nil];
        return error;
    }

    _format_context->interrupt_callback.callback = ffmpeg_interrupt_callback;
    _format_context->interrupt_callback.opaque = (__bridge void *)self;
    
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
                error = [self openVideoStream:index];
                if (!error) {
                    self.videoStreamIndex = index;
                    _video_frame = av_frame_alloc();
                    self.videoEnable = YES;
                    self.videoTimebase = sg_ff_get_timebase(_format_context->streams[self.videoStreamIndex], 0.00004);
                    self.fps = sg_ff_get_fps(_format_context->streams[self.videoStreamIndex], self.videoTimebase);
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
    
    _video_codec = codec_context;
    self.presentationSize = CGSizeMake(_video_codec->width, _video_codec->height);
    
    return error;
}

- (NSError *)openAutioStreams
{
    NSError * error = nil;
    self.audioStreamIndexs = [self fetchStreamsForMediaType:AVMEDIA_TYPE_AUDIO];
    
    if (self.audioStreamIndexs.count > 0) {
        for (NSNumber * number in self.audioStreamIndexs) {
            int index = number.intValue;
            error = [self openAudioStream:index];
            if (!error) {
                self.audioStreamIndex = index;
                _audio_frame = av_frame_alloc();
                self.audioEnable = YES;
                self.audioTimebase = sg_ff_get_timebase(_format_context->streams[self.audioStreamIndex], 0.000025);
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
    
    BOOL needSwr = YES;
    if (codec_context->sample_fmt == AV_SAMPLE_FMT_S16) {
        if (self.audioOutput.samplingRate == codec_context->sample_rate && self.audioOutput.numberOfChannels == codec_context->channels) {
            needSwr = NO;
        }
    }
    
    if (needSwr) {
        _audio_swr_context = swr_alloc_set_opts(NULL, av_get_default_channel_layout(self.audioOutput.numberOfChannels), AV_SAMPLE_FMT_S16, self.audioOutput.samplingRate, av_get_default_channel_layout(codec_context->channels), codec_context->sample_fmt, codec_context->sample_rate, 0, NULL);
        
        result = swr_init(_audio_swr_context);
        error = sg_ff_check_error_code(result, SGFFDecoderErrorCodeAuidoSwrInit);
        if (error || !_audio_swr_context) {
            if (_audio_swr_context) {
                swr_free(&_audio_swr_context);
            }
            avcodec_close(codec_context);
            return error;
        }
    }
    
    _audio_codec = codec_context;
    
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

#pragma mark - operation thread

- (void)readPacketThread
{
    [self.videoPacketQueue flush];
    if (self.videoEnable && !self.videoPacketQueue) {
        self.videoPacketQueue = [SGFFPacketQueue packetQueueWithTimebase:self.videoTimebase];
    }
    
    [self.audioFrameQueue flush];
    if (self.audioEnable && !self.audioFrameQueue) {
        self.audioFrameQueue = [SGFFFrameQueue frameQueue];
    }
    
    self.reading = YES;
    BOOL finished = NO;
    AVPacket packet;
    while (!finished) {
        if (self.closed) {
            SGFFThreadLog(@"read packet thread quit");
            break;
        }
        if (self.seeking) {
            self.endOfFile = NO;
            self.playbackFinished = NO;

            /*
            if (self.videoEnable) {
                int64_t ts = (int64_t)(self.seekToTime / self.videoTimebase);
                avformat_seek_file(_format_context, self.videoStreamIndex, ts, ts, ts, 0);
            }
            if (self.audioEnable) {
                int64_t ts = (int64_t)(self.seekToTime / self.audioTimebase);
                avformat_seek_file(_format_context, self.audioStreamIndex, ts, ts, ts, AVSEEK_FLAG_FRAME);
            }
             */
            
            int64_t ts = av_rescale(self.seekToTime * 1000, AV_TIME_BASE, 1000);
            avformat_seek_file(_format_context, -1, ts, ts, ts, 0);
            
            self.buffering = YES;
            [self.videoPacketQueue flush];
            [self.videoFrameQueue flush];
            [self.audioFrameQueue flush];
            [self.videoPacketQueue putPacket:flush_packet];
            if (self.audioEnable) {
                avcodec_flush_buffers(_audio_codec);
            }
            self.seeking = NO;
            self.seekToTime = 0;
            if (self.seekCompleteHandler) {
                self.seekCompleteHandler(YES);
                self.seekCompleteHandler = nil;
            }
            self.needUpdateAudioTimeClock = YES;
            self.currentVideoFrame = nil;
            self.currentAudioFrame = nil;
            [self updateBufferedDurationByVideo];
            [self updateBufferedDurationByAudio];
            continue;
        }
        if (self.audioFrameQueue.size + self.videoPacketQueue.size >= [SGFFPacketQueue maxCommonSize]) {
            NSTimeInterval interval = 0;
            if (self.paused) {
                interval = [SGFFPacketQueue sleepTimeIntervalForFullAndPaused];
            } else {
                interval = [SGFFPacketQueue sleepTimeIntervalForFull];
            }
            SGFFSleepLog(@"read thread sleep : %f", interval);
            [NSThread sleepForTimeInterval:interval];
            continue;
        }
        int result = av_read_frame(self->_format_context, &packet);
        if (result < 0) {
            SGFFPacketLog(@"read packet finished");
            self.endOfFile = YES;
            finished = YES;
            if ([self.delegate respondsToSelector:@selector(decoderDidEndOfFile:)]) {
                [self.delegate decoderDidEndOfFile:self];
            }
            break;
        }
        if (packet.stream_index == self.videoStreamIndex) {
            SGFFPacketLog(@"video : put packet");
            [self.videoPacketQueue putPacket:packet];
            [self updateBufferedDurationByVideo];
        } else if (packet.stream_index == self.audioStreamIndex) {
            SGFFPacketLog(@"audio : put packet");
            [self putAudioPacket:packet];
            [self updateBufferedDurationByAudio];
        }
    }
    self.reading = NO;
    [self checkBufferingStatus];
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
    while (!finished) {
        if (self.closed) {
            SGFFThreadLog(@"解线程退出");
            break;
        }
        if (self.seeking) {
            [NSThread sleepForTimeInterval:0.01];
            continue;
        }
        if (self.endOfFile && self.videoPacketQueue.count == 0) {
            SGFFDecodeLog(@"decode video frame finished");
            break;
        }
        if (self.videoFrameQueue.duration >= [SGFFFrameQueue maxVideoDuration]) {
            NSTimeInterval interval = 0;
            if (self.paused) {
                interval = [SGFFFrameQueue sleepTimeIntervalForFullAndPaused];
            } else {
                interval = [SGFFFrameQueue sleepTimeIntervalForFull];
            }
            SGFFThreadLog(@"decode thread sleep : %f", interval);
            [NSThread sleepForTimeInterval:interval];
            continue;
        }
        SGFFVideoFrame * videoFrame = [self getVideoFrameFromPacketQueue];
        if (videoFrame) {
            [self.videoFrameQueue putFrame:videoFrame];
            [self updateVideoDecodedDuration];
        }
    }
    self.decoding = NO;
    [self checkBufferingStatus];
}

- (void)displayThread
{
    while (1) {
        if (self.closed) {
            SGFFThreadLog(@"display thread quit");
            break;
        }
        if (self.seeking || self.buffering) {
            [NSThread sleepForTimeInterval:0.01];
            continue;
        }
        if (self.paused && self.currentVideoFrame) {
            if ([self.videoOutput respondsToSelector:@selector(decoder:renderVideoFrame:)]) {
                [self.videoOutput decoder:self renderVideoFrame:self.currentVideoFrame];
            }
            [NSThread sleepForTimeInterval:0.03];
            continue;
        }
        if (self.endOfFile && self.videoPacketQueue.count == 0 && self.videoFrameQueue.count == 0) {
            SGFFThreadLog(@"display finished");
            break;
        }
        if (self.videoFrameQueue.count <= 0) {
            [self updateBufferedDurationByVideo];
        }
        self.currentVideoFrame = [self.videoFrameQueue getFrame];
        if (self.currentVideoFrame) {
            
            NSTimeInterval delay = self.currentVideoFrame.duration;
            if (self.audioEnable) {
                NSTimeInterval audioTimeClock = self.audioTimeClock;
                if (self.currentVideoFrame.position >= audioTimeClock) {
                    delay = self.currentVideoFrame.duration + self.currentVideoFrame.position - audioTimeClock;
                } else {
                    delay = self.currentVideoFrame.duration - (audioTimeClock - self.currentVideoFrame.position);
                }
            }
            
            if (delay > 0.001) {
                if ([self.videoOutput respondsToSelector:@selector(decoder:renderVideoFrame:)]) {
                    [self.videoOutput decoder:self renderVideoFrame:self.currentVideoFrame];
                }
                [self updateProgressByVideo];
                if (self.endOfFile) {
                    [self updateBufferedDurationByVideo];
                }
                if (self.needUpdateAudioTimeClock && self.audioEnable) {
                    SGFFSynLog(@"------ delay : %f, video position : %f, duraion : %f", 1 / self.fps, self.currentVideoFrame.position, self.currentVideoFrame.duration);
                    [NSThread sleepForTimeInterval:1 / self.fps];
                } else {
                    SGFFSynLog(@"------ delay : %f, video position : %f, duraion : %f", delay, self.currentVideoFrame.position, self.currentVideoFrame.duration);
                    [NSThread sleepForTimeInterval:delay];
                }
            } else {
                [self updateProgressByVideo];
                if (self.endOfFile) {
                    [self updateBufferedDurationByVideo];
                }
            }
            continue;
        } else {
            if (self.endOfFile) {
                [self updateBufferedDurationByVideo];
            }
        }
    }
    [self checkBufferingStatus];
}

- (void)pause
{
    self.paused = YES;
}

- (void)resume
{
    self.paused = NO;
    if (self.playbackFinished) {
        [self seekToTime:0];
    }
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
    NSTimeInterval tempDuration = 2;
    if (!self.audioEnable) {
        tempDuration = 10;
    }
    self.progress = self.duration - time > (self.minBufferedDruation + 1) ? time : self.duration - (self.minBufferedDruation + tempDuration);
    self.seekToTime = self.progress;
    self.seekCompleteHandler = completeHandler;
    self.seeking = YES;
    
    if (self.endOfFile) {
        [self setupReadPacketOperation];
    }
}

#pragma mark - decode frames

- (SGFFVideoFrame *)getVideoFrameFromPacketQueue
{
    SGFFVideoFrame * videoFrame;
    while (!videoFrame) {
        if (self.closed) {
            return nil;
        }
        if (self.endOfFile && self.videoPacketQueue.count == 0) {
            return nil;
        }
        AVPacket packet = [self.videoPacketQueue getPacket];
        if (self.endOfFile) {
            [self updateBufferedDurationByVideo];
        }
        if (packet.data == flush_packet.data) {
            SGFFDecodeLog(@"video codec flush");
            if (self.videoEnable) {
                avcodec_flush_buffers(_video_codec);
            }
            continue;
        }
        if (packet.stream_index != self.videoStreamIndex) return nil;
        if (packet.data == NULL) return nil;
        
        int result = avcodec_send_packet(_video_codec, &packet);
        if (result < 0 && result != AVERROR(EAGAIN) && result != AVERROR_EOF) return nil;
        
        while (result >= 0) {
            result = avcodec_receive_frame(_video_codec, _video_frame);
            if (result == AVERROR(EAGAIN) || result == AVERROR_EOF || result < 0) {
                break;
            }
            videoFrame = [self getVideoFrameFromAVFrame];
        }
        av_packet_unref(&packet);
    }
    return videoFrame;
}

- (SGFFVideoFrame *)getVideoFrameFromAVFrame
{
    if (!_video_frame->data[0]) return nil;
    
    SGFFVideoFrame * videoFrame = [[SGFFVideoFrame alloc] initWithAVFrame:_video_frame width:_video_codec->width height:_video_codec->height];
    
    videoFrame.position = av_frame_get_best_effort_timestamp(_video_frame) * self.videoTimebase;
    
    const int64_t frame_duration = av_frame_get_pkt_duration(_video_frame);
    if (frame_duration) {
        videoFrame.duration = frame_duration * self.videoTimebase;
        videoFrame.duration += _video_frame->repeat_pict * self.videoTimebase * 0.5;
    } else {
        videoFrame.duration = 1.0 / self.fps;
    }
    
    return videoFrame;
}

- (SGFFAudioFrame *)fetchAudioFrame
{
    BOOL check = self.closed || self.seeking || self.buffering || self.paused || self.playbackFinished || !self.audioEnable;
    if (check) return nil;
    if (self.audioFrameQueue.count <= 0) {
        [self updateBufferedDurationByAudio];
        return nil;
    }
    self.currentAudioFrame = [self.audioFrameQueue getFrame];
    if (!self.currentAudioFrame) return nil;
    
    if (self.endOfFile) {
        [self updateBufferedDurationByAudio];
    }
    [self updateProgressByAudio];
    self.audioTimeClock = self.currentAudioFrame.position;
    return self.currentAudioFrame;
}

- (void)putAudioPacket:(AVPacket)packet
{
    if (packet.stream_index != self.audioStreamIndex) return;
    if (packet.data == NULL) return;
    
    int result = avcodec_send_packet(_audio_codec, &packet);
    if (result < 0 && result != AVERROR(EAGAIN) && result != AVERROR_EOF) return;
    
    while (result >= 0) {
        result = avcodec_receive_frame(_audio_codec, _audio_frame);
        if (result == AVERROR(EAGAIN) || result == AVERROR_EOF || result < 0) {
            break;
        }
        SGFFAudioFrame * audioFrame = [self getAudioFrameFromAVFrame];
        if (audioFrame) {
            [self.audioFrameQueue putFrame:audioFrame];
        }
    }
    av_packet_unref(&packet);
}

- (SGFFAudioFrame *)getAudioFrameFromAVFrame
{
    if (!_audio_frame->data[0]) return nil;
    
    int numberOfFrames;
    void * audioDataBuffer;
    
    if (_audio_swr_context) {
        const int ratio = MAX(1, self.audioOutput.samplingRate / _audio_codec->sample_rate) * MAX(1, self.audioOutput.numberOfChannels / _audio_codec->channels) * 2;
        const int buffer_size = av_samples_get_buffer_size(NULL, self.audioOutput.numberOfChannels, _audio_frame->nb_samples * ratio, AV_SAMPLE_FMT_S16, 1);
        
        if (!_audio_swr_buffer || _audio_swr_buffer_size < buffer_size) {
            _audio_swr_buffer_size = buffer_size;
            _audio_swr_buffer = realloc(_audio_swr_buffer, _audio_swr_buffer_size);
        }
        
        Byte * outyput_buffer[2] = {_audio_swr_buffer, 0};
        numberOfFrames = swr_convert(_audio_swr_context, outyput_buffer, _audio_frame->nb_samples * ratio, (const uint8_t **)_audio_frame->data, _audio_frame->nb_samples);
        NSError * error = sg_ff_check_error(numberOfFrames);
        if (error) {
            SGFFErrorLog(@"audio codec error : %@", error);
            return nil;
        }
        audioDataBuffer = _audio_swr_buffer;
    } else {
        if (_audio_codec->sample_fmt != AV_SAMPLE_FMT_S16) {
            SGFFErrorLog(@"audio format error");
            return nil;
        }
        audioDataBuffer = _audio_frame->data[0];
        numberOfFrames = _audio_frame->nb_samples;
    }
    
    const NSUInteger numberOfElements = numberOfFrames * self.audioOutput.numberOfChannels;
    NSMutableData *data = [NSMutableData dataWithLength:numberOfElements * sizeof(float)];
    
    float scale = 1.0 / (float)INT16_MAX ;
    vDSP_vflt16((SInt16 *)audioDataBuffer, 1, data.mutableBytes, 1, numberOfElements);
    vDSP_vsmul(data.mutableBytes, 1, &scale, data.mutableBytes, 1, numberOfElements);
    
    SGFFAudioFrame * audioFrame = [[SGFFAudioFrame alloc] init];
    audioFrame.position = av_frame_get_best_effort_timestamp(_audio_frame) * self.audioTimebase;
    audioFrame.duration = av_frame_get_pkt_duration(_audio_frame) * self.audioTimebase;
    audioFrame.samples = data;
    
    if (audioFrame.duration == 0) {
        audioFrame.duration = audioFrame.samples.length / (sizeof(float) * self.audioOutput.numberOfChannels * self.audioOutput.samplingRate);
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
    [self.videoFrameQueue destroy];
    [self.audioFrameQueue destroy];
    if (async) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self.ffmpegOperationQueue cancelAllOperations];
            [self.ffmpegOperationQueue waitUntilAllOperationsAreFinished];
            [self closePropertyValue];
            [self closeAudioStream];
            [self closeVideoStream];
            [self closeInputStream];
            [self closeOperation];
        });
    } else {
        [self.ffmpegOperationQueue cancelAllOperations];
        [self.ffmpegOperationQueue waitUntilAllOperationsAreFinished];
        [self closePropertyValue];
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

- (void)closePropertyValue
{
    self.seeking = NO;
    self.buffering = NO;
    self.paused = NO;
    self.prepareToDecode = NO;
    self.endOfFile = NO;
    self.playbackFinished = NO;
    self.currentVideoFrame = nil;
    self.currentAudioFrame = nil;
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

/*
- (void)setPaused:(BOOL)paused
{
    [self.commonLock lock];
    if (_paused != paused) {
        _paused = paused;
        if ([self.delegate respondsToSelector:@selector(decoder:didChangeValueOfPaused:)]) {
            [self.delegate decoder:self didChangeValueOfPaused:_paused];
        }
    }
    [self.commonLock unlock];
}
*/

- (void)setProgress:(NSTimeInterval)progress
{
    if (_progress != progress) {
        _progress = progress;
        if ([self.delegate respondsToSelector:@selector(decoder:didChangeValueOfProgress:)]) {
            [self.delegate decoder:self didChangeValueOfProgress:_progress];
        }
    }
}

- (void)setBuffering:(BOOL)buffering
{
    if (_buffering != buffering) {
        _buffering = buffering;
        if ([self.delegate respondsToSelector:@selector(decoder:didChangeValueOfBuffering:)]) {
            [self.delegate decoder:self didChangeValueOfBuffering:_buffering];
        }
    }
}

- (void)setPlaybackFinished:(BOOL)playbackFinished
{
    if (_playbackFinished != playbackFinished) {
        _playbackFinished = playbackFinished;
        if (_playbackFinished) {
            self.progress = self.duration;
            if ([self.delegate respondsToSelector:@selector(decoderDidPlaybackFinished:)]) {
                [self.delegate decoderDidPlaybackFinished:self];
            }
        }
    }
}

- (void)setBufferedDuration:(NSTimeInterval)bufferedDuration
{
    if (_bufferedDuration != bufferedDuration) {
        _bufferedDuration = bufferedDuration;
        if (_bufferedDuration <= 0.000001) {
            _bufferedDuration = 0;
        }
        if ([self.delegate respondsToSelector:@selector(decoder:didChangeValueOfBufferedDuration:)]) {
            [self.delegate decoder:self didChangeValueOfBufferedDuration:_bufferedDuration];
        }
        if (_bufferedDuration <= 0 && self.endOfFile) {
            self.playbackFinished = YES;
        }
        [self checkBufferingStatus];
    }
}

- (void)setAudioTimeClock:(NSTimeInterval)audioTimeClock
{
    [self.clockLock lock];
    if (_audioTimeClock != audioTimeClock) {
        _audioTimeClock = audioTimeClock;
        self.needUpdateAudioTimeClock = NO;
        SGFFSynLog(@"audio time clock : %f", _audioTimeClock);
    }
    [self.clockLock unlock];
}

- (NSTimeInterval)duration
{
    if (!_format_context) return 0;
    if (_format_context->duration == AV_NOPTS_VALUE) return MAXFLOAT;
    return (CGFloat)(_format_context->duration) / AV_TIME_BASE;
}

- (NSTimeInterval)bitrate
{
    if (!_format_context) return 0;
    return (_format_context->bit_rate / 1000.0f);
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

- (void)checkBufferingStatus
{
    if (self.buffering) {
        if (self.bufferedDuration >= self.minBufferedDruation || self.endOfFile) {
            self.buffering = NO;
        }
    } else {
        if (self.bufferedDuration <= 0.2 && !self.endOfFile) {
            self.buffering = YES;
        }
    }
}

- (void)updateBufferedDurationByVideo
{
    self.bufferedDuration = self.videoPacketQueue.duration + self.videoFrameQueue.duration;
}

- (void)updateBufferedDurationByAudio
{
    if (!self.videoEnable) {
        self.bufferedDuration = self.audioFrameQueue.duration;
    }
}

- (void)updateProgressByVideo;
{
    if (!self.audioEnable && self.videoEnable) {
        self.progress = self.currentVideoFrame.position;
    }
}

- (void)updateProgressByAudio
{
    self.progress = self.currentAudioFrame.position;
}

- (void)updateVideoDecodedDuration
{
    
}

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
    SGPlayerLog(@"SGFFDecoder release");
}

@end
