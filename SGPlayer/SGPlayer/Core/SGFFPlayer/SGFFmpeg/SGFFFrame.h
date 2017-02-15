//
//  SGFFFrame.h
//  SGMediaKit
//
//  Created by Single on 06/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "avformat.h"

typedef NS_ENUM(NSUInteger, SGFFFrameType) {
    SGFFFrameTypeVideo,
    SGFFFrameTypeAVYUVVideo,
    SGFFFrameTypeCVYUVVideo,
    SGFFFrameTypeAudio,
    SGFFFrameTypeSubtitle,
    SGFFFrameTypeArtwork,
};

typedef NS_ENUM(int, SGYUVChannel) {
    SGYUVChannelLuma = 0,
    SGYUVChannelChromaB = 1,
    SGYUVChannelChromaR = 2,
    SGYUVChannelCount = 3,
};

@interface SGFFFrame : NSObject
@property (nonatomic, assign) SGFFFrameType type;
@property (nonatomic, assign) NSTimeInterval position;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign, readonly) int size;
@end


#pragma mark - Video Frame

@interface SGFFVideoFrame : SGFFFrame

@end

// FFmpeg AVFrame YUV frame
@interface SGFFAVYUVVideoFrame : SGFFVideoFrame

{
@public
    UInt8 * channel_pixels[SGYUVChannelCount];
    int channel_lenghts[SGYUVChannelCount];
}

@property (nonatomic, assign, readonly) int width;
@property (nonatomic, assign, readonly) int height;

- (instancetype)initWithAVFrame:(AVFrame *)frame width:(int)width height:(int)height;

@end

// CoreVideo YUV frame
@interface SGFFCVYUVVideoFrame : SGFFVideoFrame

@property (nonatomic, assign, readonly) int width;
@property (nonatomic, assign, readonly) int height;

- (instancetype)initWithAVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end


#pragma mark - Audio Frame

@interface SGFFAudioFrame : SGFFFrame
@property (nonatomic, strong) NSData * samples;
@end


#pragma mark - Other Frame

@interface SGFFSubtileFrame : SGFFFrame
@end

@interface SGFFArtworkFrame : SGFFFrame
@property (nonatomic, strong) NSData * picture;
//- (UIImage *)image;
@end
