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

- (void)decoderDidOpenInputStream:(SGFFDecoder *)decoder;
- (void)decoderDidFindStreamInfo:(SGFFDecoder *)decoder;
- (void)decoder:(SGFFDecoder *)decoder didError:(NSError *)error;
- (void)decoderDidPrepareToDecodeFrames:(SGFFDecoder *)decoder;

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
