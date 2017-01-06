//
//  SGFFDecoder.h
//  SGMediaKit
//
//  Created by Single on 05/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>

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
- (void)decoder:(SGFFDecoder *)decoder didError:(NSError *)error;

@end

@interface SGFFDecoder : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)decoderWithContentURL:(NSURL *)contentURL delegate:(id <SGFFDecoderDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;

@property (nonatomic, copy, readonly) NSURL * contentURL;
@property (nonatomic, copy, readonly) NSDictionary * metadata;

@property (nonatomic, assign, readonly) float fps;
@property (nonatomic, assign, readonly) float timebase;

- (void)decodeFrames;
- (void)closeFile;

@end
