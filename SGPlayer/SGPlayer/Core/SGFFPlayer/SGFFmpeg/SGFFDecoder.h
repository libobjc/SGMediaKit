//
//  SGFFDecoder.h
//  SGMediaKit
//
//  Created by Single on 05/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SGFFFrame.h"

typedef NS_ENUM(NSUInteger, SGFFDecoderErrorCode) {
    SGFFDecoderErrorCodeFormatCreate,
    SGFFDecoderErrorCodeFormatOpenInput,
    SGFFDecoderErrorCodeFormatFindStreamInfo,
    SGFFDecoderErrorCodeStreamNotFound,
    SGFFDecoderErrorCodeCodecContextCreate,
    SGFFDecoderErrorCodeCodecContextSetParam,
    SGFFDecoderErrorCodeCodecFindDecoder,
    SGFFDecoderErrorCodeCodecVideoSendPacket,
    SGFFDecoderErrorCodeCodecAudioSendPacket,
    SGFFDecoderErrorCodeCodecVideoReceiveFrame,
    SGFFDecoderErrorCodeCodecAudioReceiveFrame,
    SGFFDecoderErrorCodeCodecOpen2,
    SGFFDecoderErrorCodeAuidoSwrInit,
};

@class SGFFDecoder;

@protocol SGFFDecoderDelegate <NSObject>

@optional

// open input stream
- (void)decoderWillOpenInputStream:(SGFFDecoder *)decoder;
- (void)decoderDidOpenInputStream:(SGFFDecoder *)decoder;

// open video/audio stream
- (void)decoderDidOpenVideoStream:(SGFFDecoder *)decoder;
- (void)decoderDidOpenAudioStream:(SGFFDecoder *)decoder;

- (void)decoderDidPrepareToDecodeFrames:(SGFFDecoder *)decoder;     // prepare decode frames
- (void)decoderDidEndOfFile:(SGFFDecoder *)decoder;     // end of file
- (void)decoderDidPlaybackFinished:(SGFFDecoder *)decoder;
- (void)decoder:(SGFFDecoder *)decoder didError:(NSError *)error;       // error callback

// value change
- (void)decoder:(SGFFDecoder *)decoder didChangeValueOfBuffering:(BOOL)buffering;
- (void)decoder:(SGFFDecoder *)decoder didChangeValueOfBufferedDuration:(NSTimeInterval)bufferedDuration;
- (void)decoder:(SGFFDecoder *)decoder didChangeValueOfProgress:(NSTimeInterval)progress;

/*
- (void)decoder:(SGFFDecoder *)decoder didChangeValueOfPaused:(BOOL)paused;
*/

@end

@protocol SGFFDecoderVideoOutput <NSObject>

- (void)decoder:(SGFFDecoder *)decoder renderVideoFrame:(SGFFVideoFrame *)videoFrame;

@end

@protocol SGFFDecoderAudioOutput <NSObject>

- (Float64)samplingRate;
- (UInt32)numberOfChannels;

@optional
- (void)decoder:(SGFFDecoder *)decoder audioOutputEnable:(BOOL)audioOutputEnable;

@end

@interface SGFFDecoder : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)decoderWithContentURL:(NSURL *)contentURL delegate:(id <SGFFDecoderDelegate>)delegate videoOutput:(id <SGFFDecoderVideoOutput>)videoOutput audioOutput:(id <SGFFDecoderAudioOutput>)audioOutput;

@property (nonatomic, strong, readonly) NSError * error;

@property (nonatomic, copy, readonly) NSURL * contentURL;
@property (nonatomic, copy, readonly) NSDictionary * metadata;
@property (nonatomic, assign, readonly) CGSize presentationSize;
@property (nonatomic, assign, readonly) NSTimeInterval fps;
@property (nonatomic, assign, readonly) NSTimeInterval bitrate;
@property (nonatomic, assign, readonly) NSTimeInterval progress;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) NSTimeInterval bufferedDuration;

@property (nonatomic, assign) NSTimeInterval minBufferedDruation;
@property (nonatomic, assign) CGFloat volume;
@property (nonatomic, assign) BOOL hardwareDecoderEnable;       // default is YES;

@property (nonatomic, assign, readonly) BOOL buffering;

@property (nonatomic, assign, readonly) BOOL playbackFinished;
@property (atomic, assign, readonly) BOOL closed;
@property (atomic, assign, readonly) BOOL endOfFile;
@property (atomic, assign, readonly) BOOL paused;
@property (atomic, assign, readonly) BOOL seeking;
@property (atomic, assign, readonly) BOOL reading;
@property (atomic, assign, readonly) BOOL decoding;
@property (atomic, assign, readonly) BOOL prepareToDecode;

@property (atomic, assign, readonly) BOOL videoEnable;
@property (atomic, assign, readonly) BOOL audioEnable;

@property (atomic, assign, readonly) int videoStreamIndex;
@property (atomic, assign, readonly) int audioStreamIndex;

@property (nonatomic, copy, readonly) NSArray <NSNumber *> * videoStreamIndexs;
@property (nonatomic, copy, readonly) NSArray <NSNumber *> * audioStreamIndexs;

@property (nonatomic, copy, readonly) NSString * videoPixelForamtName;

- (void)pause;
- (void)resume;
- (SGFFAudioFrame *)fetchAudioFrame;

@property (nonatomic, assign, readonly) BOOL seekEnable;
- (void)seekToTime:(NSTimeInterval)time;
- (void)seekToTime:(NSTimeInterval)time completeHandler:(void (^)(BOOL finished))completeHandler;

- (void)open;
- (void)closeFile;      // when release of active calls, or when called in dealloc might block the thread

@end
