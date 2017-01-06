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

@interface SGFFDecoder ()

{
    AVFormatContext * _format_context;
    AVStream * _video_stream;
    AVStream * _audio_stream;
}

@property (nonatomic, weak) id <SGFFDecoderDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegate_queue;
@property (nonatomic, strong) dispatch_queue_t open_steam_queue;

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, copy, readonly) NSString * contentURLString;
@property (nonatomic, copy) NSDictionary * metadata;

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
        self.open_steam_queue = dispatch_queue_create("sgffdecoder.open.stream.queue", DISPATCH_QUEUE_SERIAL);
        
        [self openFile];
    }
    return self;
}

#pragma mark - open stream

- (void)openFile
{
    dispatch_async(self.open_steam_queue, ^{
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
                    _video_stream = _format_context->streams[index];
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
                _audio_stream = _format_context->streams[index];
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

- (void)fetchTime
{
//        _video_frame = av_frame_alloc();
//    
//        if (stream->time_base.den && stream->time_base.num) {
//            _time_base = av_q2d(stream->time_base);
//        } else {
//            _time_base = 0.04;
//        }
//    
//        if (stream->avg_frame_rate.den && stream->avg_frame_rate.num) {
//            _fps = av_q2d(stream->avg_frame_rate);
//        } else {
//            _fps = 1.0 / _time_base;
//        }
}

#pragma mark - decode frames

- (void)decodeFrames
{
    /*
    AVPacket packet;
    
    BOOL finished = NO;
    while (!finished) {
        
        int errorCode = av_read_frame(_format_context, &packet);
        NSError * error = checkErrorCode(errorCode);
        if (error) {
            NSLog(@"error : %@", error);
            break;
        }
        
        if (packet.stream_index == _video_strame->index) {
            int packet_size = packet.size;
            if (packet_size > 0) {
                
                int gotframe = 0;
                int result = avcodec_decode_video2(_video_strame->codec, _video_frame, &gotframe, &packet);
                NSError * error = checkErrorCode(result);
                if (error) {
                    NSLog(@"decode video error : %@", error);
                    break;
                }
                
                if (gotframe) {
                    
                    avpicture_alloc(&(_picture), AV_PIX_FMT_RGB24, _video_strame->codec->width, _video_strame->codec->height);
                    
                    _sws_context = sws_getCachedContext(_sws_context,
                                                        _video_strame->codec->width,
                                                        _video_strame->codec->height,
                                                        _video_strame->codec->pix_fmt,
                                                        _video_strame->codec->width,
                                                        _video_strame->codec->height,
                                                        AV_PIX_FMT_RGB24,
                                                        SWS_FAST_BILINEAR,
                                                        NULL, NULL, NULL);
                    
                    sws_scale(_sws_context, (const uint8_t **)_video_frame->data, _video_frame->linesize, 0, _video_strame->codec->height, _picture.data,
                              _picture.linesize);
                    
                    NSData * data = [NSData dataWithBytes:_picture.data length:_picture.linesize[0] * _video_strame->codec->height];
                    
                    UIImage * image = nil;
                    
                    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)(data));
                    if (provider) {
                        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
                        if (colorSpace) {
                            CGImageRef imageRef = CGImageCreate(_video_strame->codec->width,
                                                                _video_strame->codec->height,
                                                                8,
                                                                24,
                                                                _picture.linesize[0],
                                                                colorSpace,
                                                                kCGBitmapByteOrderDefault,
                                                                provider,
                                                                NULL,
                                                                YES, // NO
                                                                kCGRenderingIntentDefault);
                            
                            if (imageRef) {
                                image = [UIImage imageWithCGImage:imageRef];
                                CGImageRelease(imageRef);
                            }
                            CGColorSpaceRelease(colorSpace);
                        }
                        CGDataProviderRelease(provider);
                    }
                    
                    if (image) {
                        static dispatch_once_t onceToken;
                        dispatch_once(&onceToken, ^{
                            NSString  *jpgPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Test.jpg"];
                            [UIImageJPEGRepresentation(image, 1.0) writeToFile:jpgPath atomically:YES];
                        });
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [(UIImageView *)self.view setImage:image];
                    });
                }
            }
        }
    }
     */
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
    if (_video_stream) {
        return YES;
    }
    return NO;
}

- (BOOL)audioEnable
{
    if (_audio_stream) {
        return YES;
    }
    return NO;
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
