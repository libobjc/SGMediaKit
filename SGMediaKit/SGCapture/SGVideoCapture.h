//
//  SGVideoCapture.h
//  SGMediaKit
//
//  Created by Single on 23/11/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SGVideoConfiguration.h"

typedef NS_ENUM(NSUInteger, SGVideoCaptureErrorCode) {
    SGVideoCaptureErrorCodeUnknown,
    SGVideoCaptureErrorCodeRunning,
    SGVideoCaptureErrorCodeRecording,
};

typedef NS_ENUM(NSUInteger, SGCameraPosition) {
    SGCameraPositionFront,
    SGCameraPositionBack,
};

typedef NS_ENUM(NSUInteger, SGFocusMode) {
    SGFocusModeAutomatic,
    SGFocusModeManual,
};

@class SGVideoCapture;

@protocol SGVideoCaptureDelegate <NSObject>

@optional;

- (void)videoCaptureWillStartRunning:(SGVideoCapture *)videoCapture;
- (void)videoCaptureDidStartRunning:(SGVideoCapture *)videoCapture;
- (void)videoCaptureWillStopRunning:(SGVideoCapture *)videoCapture;
- (void)videoCaptureDidStopRunning:(SGVideoCapture *)videoCapture;

- (void)videoCapture:(SGVideoCapture *)videoCapture willStartRecordingfToFileURL:(NSURL *)fileURL;
- (void)videoCapture:(SGVideoCapture *)videoCapture didStartRecordingToFileURL:(NSURL *)fileURL;
- (void)videoCapture:(SGVideoCapture *)videoCapture willFinishRecordingToFileURL:(NSURL *)fileURL;
- (void)videoCapture:(SGVideoCapture *)videoCapture didFinishRecordingToFileURL:(NSURL *)fileURL;

- (void)videoCapture:(SGVideoCapture *)videoCapture outputPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

@interface SGVideoCapture : NSObject

+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithVideoConfiguration:(SGVideoConfiguration *)videoConfiguration NS_DESIGNATED_INITIALIZER;

@property (nonatomic, assign, readonly) BOOL running;
@property (nonatomic, assign, readonly) BOOL recording;
@property (nonatomic, weak) id <SGVideoCaptureDelegate> delegate;
@property (nonatomic, strong, readonly) UIView * view;

@property (nonatomic, assign, readonly) SGCameraPosition cameraPosition;   // default is Front
- (BOOL)setCameraPosition:(SGCameraPosition)cameraPosition error:(NSError **)error;

@property (nonatomic, assign, readonly) BOOL torch;   // default is off
@property (nonatomic, assign, readonly) BOOL torchEnable;
- (BOOL)setTorch:(BOOL)torch error:(NSError **)error;

@property (nonatomic, assign, readonly) SGFocusMode focusMode;
@property (nonatomic, assign, readonly) BOOL focusModeAutomaticEnable;
@property (nonatomic, assign, readonly) BOOL focusModeManualEnable;
- (BOOL)setFocusMode:(SGFocusMode)focusMode error:(NSError **)error;
- (BOOL)setFocusPointOfInterest:(CGPoint)focusPointOfInterest error:(NSError **)error;

- (void)startRunning;
- (void)stopRunning;

- (BOOL)startRecordingWithFileURL:(NSURL *)fileURL error:(NSError **)error;
- (void)finishRecordingWithCompletionHandler:(void (^)(NSURL * fileURL, NSError * error))completionHandler;

@end
