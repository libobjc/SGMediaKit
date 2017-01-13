//
//  SGFFDecoder.h
//  SGMediaKit
//
//  Created by Single on 05/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SGFFFrame.h"

typedef NS_ENUM(NSUInteger, SGFFDecoderErrorCode) {
    SGFFDecoderErrorCodeFormatOpenInput,
    SGFFDecoderErrorCodeFormatFindStreamInfo,
    SGFFDecoderErrorCodeStreamNotFound,
    SGFFDecoderErrorCodeCodecFindDecoder,
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

// decode frames
- (void)decoderDidPrepareToDecodeFrames:(SGFFDecoder *)decoder;
- (void)decoder:(SGFFDecoder *)decoder didDecodeFrames:(NSArray <SGFFFrame *> *)frames;

// end of file
- (void)decoderDidEndOfFile:(SGFFDecoder *)decoder;

// error callback
- (void)decoder:(SGFFDecoder *)decoder didError:(NSError *)error;

@end

@interface SGFFDecoder : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)decoderWithContentURL:(NSURL *)contentURL delegate:(id <SGFFDecoderDelegate>)delegate;

@property (nonatomic, copy, readonly) NSURL * contentURL;
@property (nonatomic, copy, readonly) NSDictionary * metadata;
@property (nonatomic, assign, readonly) CGSize presentationSize;

@property (nonatomic, assign, readonly) NSTimeInterval fps;
@property (nonatomic, assign, readonly) NSTimeInterval position;
@property (nonatomic, assign, readonly) NSTimeInterval duration;

@property (nonatomic, assign, readonly) BOOL videoEnable;
@property (nonatomic, assign, readonly) BOOL audioEnable;

@property (nonatomic, assign, readonly) BOOL endOfFile;
@property (nonatomic, assign, readonly) BOOL decoding;
@property (nonatomic, assign, readonly) BOOL prepareToDecode;

- (void)decodeFrames;
- (void)decodeFramesWithDuration:(NSTimeInterval)duration;

@property (nonatomic, assign, readonly) BOOL seekEnable;
- (void)seekToTime:(NSTimeInterval)time completeHandler:(void (^)(BOOL finished))completeHandler;

- (void)closeFile;      // when release of active calls, or when called in dealloc might block the thread

@end
