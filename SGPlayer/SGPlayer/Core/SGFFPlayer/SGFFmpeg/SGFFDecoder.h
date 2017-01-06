//
//  SGFFDecoder.h
//  SGMediaKit
//
//  Created by Single on 05/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFFrame.h"

@class SGFFDecoder;

@protocol SGFFDecoderDelegate <NSObject>

// open input stream
- (void)decoderDidOpenInputStream:(SGFFDecoder *)decoder;
- (void)decoder:(SGFFDecoder *)decoder openInputStreamError:(NSError *)error;

// open video stream
- (void)decoderDidOpenVideoStream:(SGFFDecoder *)decoder;
- (void)decoder:(SGFFDecoder *)decoder openVideoStreamError:(NSError *)error;

// open audio stream
- (void)decoderDidOpenAudioStream:(SGFFDecoder *)decoder;
- (void)decoder:(SGFFDecoder *)decoder openAudioStreamError:(NSError *)error;

- (void)decoderDidPrepareToDecodeFrames:(SGFFDecoder *)decoder;
- (void)decoder:(SGFFDecoder *)decoder didDecodeFrames:(NSArray <SGFFFrame *> *)frames;
- (void)decoder:(SGFFDecoder *)decoder didError:(NSError *)error;

- (void)decoderDidEndOfFile:(SGFFDecoder *)decoder;

@end

@interface SGFFDecoder : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)decoderWithContentURL:(NSURL *)contentURL delegate:(id <SGFFDecoderDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;

@property (nonatomic, copy, readonly) NSURL * contentURL;
@property (nonatomic, copy, readonly) NSDictionary * metadata;

@property (nonatomic, assign, readonly) BOOL videoEnable;
@property (nonatomic, assign, readonly) BOOL audioEnable;

@property (nonatomic, assign, readonly) BOOL endOfFile;
@property (nonatomic, assign, readonly) BOOL decoding;

@property (nonatomic, assign, readonly) float fps;
@property (nonatomic, assign, readonly) NSTimeInterval position;

- (void)decodeFrames;
- (void)decodeFramesWithDuration:(NSTimeInterval)duration;
- (void)closeFile;

@end
