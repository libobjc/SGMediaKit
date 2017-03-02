//
//  SGFFVideoFrame.h
//  SGMediaKit
//
//  Created by Single on 2017/2/17.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGFFFrame.h"
#import <AVFoundation/AVFoundation.h>
#import "avformat.h"

typedef NS_ENUM(int, SGYUVChannel) {
    SGYUVChannelLuma = 0,
    SGYUVChannelChromaB = 1,
    SGYUVChannelChromaR = 2,
    SGYUVChannelCount = 3,
};

@class SGFFVideoFrame;

@protocol SGFFVideoFrameDelegate <NSObject>

- (void)videoFrameDidStartDrawing:(SGFFVideoFrame *)videoFrame;
- (void)videoFrameDidStopDrawing:(SGFFVideoFrame *)videoFrame;

@end

@interface SGFFVideoFrame : SGFFFrame

@property (nonatomic, weak) id <SGFFVideoFrameDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL drawing;

- (void)startDrawing;
- (void)stopDrawing;

@end


// FFmpeg AVFrame YUV frame
@interface SGFFAVYUVVideoFrame : SGFFVideoFrame

{
@public
    UInt8 * channel_pixels[SGYUVChannelCount];
}

@property (nonatomic, assign, readonly) int width;
@property (nonatomic, assign, readonly) int height;

+ (instancetype)videoFrame;
- (void)setFrameData:(AVFrame *)frame width:(int)width height:(int)height;

@end


// CoreVideo YUV frame
@interface SGFFCVYUVVideoFrame : SGFFVideoFrame

@property (nonatomic, assign, readonly) CVPixelBufferRef pixelBuffer;

- (instancetype)initWithAVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
