//
//  SGVideoCapture.h
//  SGMediaKit
//
//  Created by Single on 23/11/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SGVideoCaptureErrorCode) {
    SGVideoCaptureErrorCodeUnknown,
    SGVideoCaptureErrorCodeRunning,
    SGVideoCaptureErrorCodeRecording,
};

@class SGVideoCapture;

@protocol SGVideoCaptureDelegate <NSObject>

@optional;
- (void)videoCaptureWillStartRunning:(SGVideoCapture *)videoCapture;
- (void)videoCaptureDidStartRunning:(SGVideoCapture *)videoCapture;
- (void)videoCaptureWillStopRunning:(SGVideoCapture *)videoCapture;
- (void)videoCaptureDidStopRunning:(SGVideoCapture *)videoCapture;
- (void)videoCaptureWillStartRecording:(SGVideoCapture *)videoCapture fileURL:(NSURL *)fileURL;
- (void)videoCaptureDidStartRecording:(SGVideoCapture *)videoCapture fileURL:(NSURL *)fileURL;
- (void)videoCaptureWillFinishRecording:(SGVideoCapture *)videoCapture fileURL:(NSURL *)fileURL;
- (void)videoCaptureDidFinishRecording:(SGVideoCapture *)videoCapture fileURL:(NSURL *)fileURL;
- (void)videoCapture:(SGVideoCapture *)videoCapture outputPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

@interface SGVideoCapture : NSObject

@property (nonatomic, assign, readonly) BOOL running;
@property (nonatomic, assign, readonly) BOOL recording;
@property (nonatomic, weak) id <SGVideoCaptureDelegate> delegate;
@property (nonatomic, strong, readonly) UIView * view;

- (void)startRunning;
- (void)stopRunning;

- (BOOL)startRecordingWithFileURL:(NSURL *)fileURL error:(NSError **)error;
- (void)finishRecordingWithCompletionHandler:(void (^)(NSURL * fileURL, NSError * error))completionHandler;

@end
