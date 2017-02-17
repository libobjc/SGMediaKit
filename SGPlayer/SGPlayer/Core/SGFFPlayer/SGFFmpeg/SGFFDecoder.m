    //
//  SGFFDecoder.m
//  SGMediaKit
//
//  Created by Single on 05/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFDecoder.h"
#import "SGFFAudioDecoder.h"
#import "SGFFVideoDecoder.h"
#import "SGFFTools.h"

static int ffmpeg_interrupt_callback(void *ctx)
{
    SGFFDecoder * obj = (__bridge SGFFDecoder *)ctx;
    return obj.closed;
}

@interface SGFFDecoder () <SGFFAudioDecoderDelegate, SGFFVideoDecoderDlegate>

{
    AVFormatContext * _format_context;
}

@property (nonatomic, weak) id <SGFFDecoderDelegate> delegate;
@property (nonatomic, weak) id <SGFFDecoderVideoOutput> videoOutput;
@property (nonatomic, weak) id <SGFFDecoderAudioOutput> audioOutput;

@property (nonatomic, strong) NSOperationQueue * ffmpegOperationQueue;
@property (nonatomic, strong) NSInvocationOperation * openFileOperation;
@property (nonatomic, strong) NSInvocationOperation * readPacketOperation;
@property (nonatomic, strong) NSInvocationOperation * decodeFrameOperation;
@property (nonatomic, strong) NSInvocationOperation * displayOperation;

@property (nonatomic, strong) SGFFAudioDecoder * audioDecoder;
@property (nonatomic, strong) SGFFVideoDecoder * videoDecoder;

@property (nonatomic, strong) NSError * error;

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, copy, readonly) NSString * contentURLString;
@property (nonatomic, copy) NSDictionary * metadata;
@property (nonatomic, assign) CGSize presentationSize;
@property (nonatomic, assign) NSTimeInterval progress;
@property (nonatomic, assign) NSTimeInterval bufferedDuration;

@property (nonatomic, assign) BOOL buffering;

@property (nonatomic, assign) BOOL playbackFinished;
@property (atomic, assign) BOOL closed;
@property (atomic, assign) BOOL endOfFile;
@property (atomic, assign) BOOL paused;
@property (atomic, assign) BOOL seeking;
@property (atomic, assign) BOOL reading;
@property (atomic, assign) BOOL prepareToDecode;

@property (atomic, assign) BOOL videoEnable;
@property (atomic, assign) BOOL audioEnable;

@property (atomic, assign) int videoStreamIndex;
@property (atomic, assign) int audioStreamIndex;

@property (atomic, assign) NSTimeInterval videoTimebase;

@property (nonatomic, copy) NSArray <NSNumber *> * videoStreamIndexs;
@property (nonatomic, copy) NSArray <NSNumber *> * audioStreamIndexs;

@property (nonatomic, assign) NSTimeInterval seekToTime;
@property (nonatomic, assign) NSTimeInterval seekMinTime;       // default is 0
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
        });
        
        self.contentURL = contentURL;
        self.delegate = delegate;
        self.videoOutput = videoOutput;
        self.audioOutput = audioOutput;
        
        self.videoStreamIndex = -1;
        self.audioStreamIndex = -1;
        
        self.hardwareDecoderEnable = YES;
    }
    return self;
}

#pragma mark - setup operations

- (void)open
{
    [self setupOperationQueue];
}

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
            self.decodeFrameOperation = [[NSInvocationOperation alloc] initWithTarget:self.videoDecoder selector:@selector(decodeFrameThread) object:nil];
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
                AVCodecContext * codec_context;
                error = [self openVideoStream:index codecContext:&codec_context];
                if (!error) {
                    self.videoStreamIndex = index;
                    self.videoEnable = YES;
                    NSTimeInterval timebase = sg_ff_get_timebase(_format_context->streams[self.videoStreamIndex], 0.00004);
                    NSTimeInterval fps = sg_ff_get_fps(_format_context->streams[self.videoStreamIndex], self.videoTimebase);
                    self.videoDecoder = [SGFFVideoDecoder decoderWithCodecContext:codec_context
                                                                         timebase:timebase
                                                                              fps:fps
                                                                         delegate:self];
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
    
    self.presentationSize = CGSizeMake(codec_context->width, codec_context->height);
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
                NSTimeInterval timebase = sg_ff_get_timebase(_format_context->streams[self.audioStreamIndex], 0.000025);
                self.audioDecoder = [SGFFAudioDecoder decoderWithCodecContext:codec_context
                                                                     timebase:timebase
                                                                     delegate:self];
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

#pragma mark - operation thread

static int max_packet_buffer_size = 20 * 1024 * 1024;
static NSTimeInterval max_packet_sleep_full_time_interval = 0.1;
static NSTimeInterval max_packet_sleep_full_and_pause_time_interval = 0.5;

- (void)readPacketThread
{
    [self.videoDecoder flush];
    [self.audioDecoder flush];
    
    self.reading = YES;
    BOOL finished = NO;
    AVPacket packet;
    while (!finished) {
        if (self.closed || self.error) {
            SGFFThreadLog(@"read packet thread quit");
            break;
        }
        if (self.seeking) {
            self.endOfFile = NO;
            self.playbackFinished = NO;

            int64_t ts = av_rescale(self.seekToTime * 1000, AV_TIME_BASE, 1000);
            avformat_seek_file(_format_context, -1, ts, ts, ts, 0);
            
            self.buffering = YES;
            [self.audioDecoder flush];
            [self.videoDecoder flush];
            self.videoDecoder.paused = NO;
            self.videoDecoder.endOfFile = NO;
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
        if (self.audioDecoder.size + self.videoDecoder.packetSize >= max_packet_buffer_size) {
            NSTimeInterval interval = 0;
            if (self.paused) {
                interval = max_packet_sleep_full_and_pause_time_interval;
            } else {
                interval = max_packet_sleep_full_time_interval;
            }
            SGFFSleepLog(@"read thread sleep : %f", interval);
            [NSThread sleepForTimeInterval:interval];
            continue;
        }
        
        // read frame
        int result = av_read_frame(self->_format_context, &packet);
        if (result < 0)
        {
            SGFFPacketLog(@"read packet finished");
            self.endOfFile = YES;
            self.videoDecoder.endOfFile = YES;
            finished = YES;
            if ([self.delegate respondsToSelector:@selector(decoderDidEndOfFile:)]) {
                [self.delegate decoderDidEndOfFile:self];
            }
            break;
        }
        if (packet.stream_index == self.videoStreamIndex)
        {
            SGFFPacketLog(@"video : put packet");
            [self.videoDecoder putPacket:packet];
            [self updateBufferedDurationByVideo];
        }
        else if (packet.stream_index == self.audioStreamIndex)
        {
            SGFFPacketLog(@"audio : put packet");
            int result = [self.audioDecoder putPacket:packet];
            if (result < 0) {
                self.error = sg_ff_check_error_code(result, SGFFDecoderErrorCodeCodecAudioSendPacket);
                [self delegateErrorCallback];
                continue;
            }
            [self updateBufferedDurationByAudio];
        }
    }
    self.reading = NO;
    [self checkBufferingStatus];
}

- (void)displayThread
{
    while (1) {
        if (self.closed || self.error) {
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
        if (self.endOfFile && self.videoDecoder.empty) {
            SGFFThreadLog(@"display finished");
            break;
        }
        if (self.videoDecoder.frameEmpty) {
            [self updateBufferedDurationByVideo];
        }
        self.currentVideoFrame = [self.videoDecoder getFrameSync];
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
                    SGFFSynLog(@"------ delay : %f, video position : %f, duraion : %f", 1 / self.videoDecoder.fps, self.currentVideoFrame.position, self.currentVideoFrame.duration);
                    SGFFSleepLog(@"display thread sleep : %f", interval);
                    [NSThread sleepForTimeInterval:1 / self.videoDecoder.fps];
                } else {
                    SGFFSynLog(@"------ delay : %f, video position : %f, duraion : %f", delay, self.currentVideoFrame.position, self.currentVideoFrame.duration);
                    SGFFSleepLog(@"display thread sleep : %f", interval);
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
    NSTimeInterval tempDuration = 8;
    if (!self.audioEnable) {
        tempDuration = 15;
    }
    
    NSTimeInterval seekMaxTime = self.duration - (self.minBufferedDruation + tempDuration);
    if (seekMaxTime < self.seekMinTime) {
        seekMaxTime = self.seekMinTime;
    }
    if (time > seekMaxTime) {
        time = seekMaxTime;
    } else if (time < self.seekMinTime) {
        time = self.seekMinTime;
    }
    self.progress = time;
    self.seekToTime = time;
    self.seekCompleteHandler = completeHandler;
    self.seeking = YES;
    self.videoDecoder.paused = YES;
    
    if (self.endOfFile) {
        [self setupReadPacketOperation];
    }
}

- (SGFFAudioFrame *)fetchAudioFrame
{
    BOOL check = self.closed || self.seeking || self.buffering || self.paused || self.playbackFinished || !self.audioEnable;
    if (check) return nil;
    if (self.audioDecoder.empty) {
        [self updateBufferedDurationByAudio];
        return nil;
    }
    self.currentAudioFrame = [self.audioDecoder getFrameSync];
    if (!self.currentAudioFrame) return nil;
    
    if (self.endOfFile) {
        [self updateBufferedDurationByAudio];
    }
    [self updateProgressByAudio];
    self.audioTimeClock = self.currentAudioFrame.position;
    return self.currentAudioFrame;
}

#pragma mark - close stream

- (void)closeFile
{
    [self closeFileAsync:YES];
}

- (void)closeFileAsync:(BOOL)async
{
    if (!self.closed) {
        self.closed = YES;
        [self.videoDecoder destroy];
        [self.audioDecoder destroy];
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
    self.videoDecoder.paused = NO;
    self.videoDecoder.endOfFile = NO;
}

- (void)closeVideoStream
{
    self.videoEnable = NO;
    self.videoStreamIndex = -1;
}

- (void)closeAudioStream
{
    self.audioEnable = NO;
    self.audioStreamIndex = -1;
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

- (NSTimeInterval)fps
{
    return self.videoDecoder.fps;
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
    self.bufferedDuration = self.videoDecoder.duration;
}

- (void)updateBufferedDurationByAudio
{
    if (!self.videoEnable) {
        self.bufferedDuration = self.audioDecoder.duration;
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

#pragma delegate callback

- (void)audioDecoder:(SGFFAudioDecoder *)audioDecoder samplingRate:(Float64 *)samplingRate
{
    * samplingRate = self.audioOutput.samplingRate;
}

- (void)audioDecoder:(SGFFAudioDecoder *)audioDecoder channelCount:(UInt32 *)channelCount
{
    * channelCount = self.audioOutput.numberOfChannels;
}

- (void)videoDecoderNeedUpdateBufferedDuration:(SGFFVideoDecoder *)videoDecoder
{
    [self updateBufferedDurationByVideo];
}

- (void)videoDecoderNeedCheckBufferingStatus:(SGFFVideoDecoder *)videoDecoder
{
    [self checkBufferingStatus];
}

- (void)videoDecoder:(SGFFVideoDecoder *)videoDecoder didError:(NSError *)error
{
    self.error = error;
    [self delegateErrorCallback];
}

@end
