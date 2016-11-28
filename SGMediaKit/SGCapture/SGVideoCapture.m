//
//  SGVideoCapture.m
//  SGMediaKit
//
//  Created by Single on 23/11/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import "SGVideoCapture.h"
#import <GPUImage/GPUImageFramework.h>
#import "SGVideoCapturePreview.h"

@interface SGVideoCapture ()

@property (nonatomic, strong) SGVideoConfiguration * videoConfiguration;

@property (nonatomic, assign) BOOL running;
@property (nonatomic, assign) BOOL recording;
@property (nonatomic, strong) GPUImageVideoCamera * videoCamera;
@property (nonatomic, strong) GPUImageFilter * filter;
@property (nonatomic, strong) GPUImageMovieWriter * writer;
@property (nonatomic, copy) NSURL * fileURL;
@property (nonatomic, strong) SGVideoCapturePreview * preview;

@end

@implementation SGVideoCapture

- (instancetype)initWithVideoConfiguration:(SGVideoConfiguration *)videoConfiguration
{
    if (self = [super init]) {
        self.videoConfiguration = videoConfiguration;
    }
    return self;
}

- (void)reloadFilter
{
    [self.filter removeTarget:self.preview.gpuImageView];
    self.filter = [[GPUImageFilter alloc] init];
    [self.filter addTarget:self.preview.gpuImageView];
    [self tryAddWriterToFilter];
    [self.videoCamera addTarget:self.filter];
    
    __weak typeof(self) weakSelf = self;
    [self.filter setFrameProcessingCompletionBlock:^(GPUImageOutput * output, CMTime time) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf frameProcessingHandler:output time:time];
    }];
}

- (void)frameProcessingHandler:(GPUImageOutput *)output time:(CMTime)time
{
    @autoreleasepool {
        CVPixelBufferRef pixelBuffer = output.framebufferForOutput.pixelBuffer;
        if (pixelBuffer && self.delegate && [self.delegate respondsToSelector:@selector(videoCapture:outputPixelBuffer:)]) {
            [self.delegate videoCapture:self outputPixelBuffer:pixelBuffer];
        }
    }
}

- (void)startRunning
{
    if (!self.running) {
        [self reloadFilter];
        if ([self.delegate respondsToSelector:@selector(videoCaptureWillStartRunning:)]) {
            [self.delegate videoCaptureWillStartRunning:self];
        }
        self.running = YES;
        [self.videoCamera startCameraCapture];
        if ([self.delegate respondsToSelector:@selector(videoCaptureDidStartRunning:)]) {
            [self.delegate videoCaptureDidStartRunning:self];
        }
    }
}

- (void)stopRunning
{
    if (self.running) {
        if ([self.delegate respondsToSelector:@selector(videoCaptureWillStopRunning:)]) {
            [self.delegate videoCaptureWillStopRunning:self];
        }
        self.running = NO;
        [self.videoCamera stopCameraCapture];
        if ([self.delegate respondsToSelector:@selector(videoCaptureDidStopRunning:)]) {
            [self.delegate videoCaptureDidStopRunning:self];
        }
    }
}

- (BOOL)startRecordingWithFileURL:(NSURL *)fileURL error:(NSError *__autoreleasing *)error
{
    if (self.recording) {
        NSError * err = [NSError errorWithDomain:@"已经在在录制" code:SGVideoCaptureErrorCodeRecording userInfo:nil];
        * error = err;
        return NO;
    }
    if (!fileURL.isFileURL) {
        NSError * err = [NSError errorWithDomain:@"fileURL 不是可用的文件URL" code:SGVideoCaptureErrorCodeRecording userInfo:nil];
        * error = err;
        return NO;
    }
    
    self.fileURL = fileURL;
    [self setupWriter];
    if ([self.delegate respondsToSelector:@selector(videoCapture:willStartRecordingfToFileURL:)]) {
        [self.delegate videoCapture:self willStartRecordingfToFileURL:fileURL];
    }
    self.recording = YES;
    [self.writer startRecording];
    if ([self.delegate respondsToSelector:@selector(videoCaptureDidStartRecording:fileURL:)]) {
        [self.delegate videoCapture:self didStartRecordingToFileURL:fileURL];
    }
    return YES;
}

- (void)finishRecordingWithCompletionHandler:(void (^)(NSURL *, NSError *))completionHandler
{
    if (self.recording) {
        if ([self.delegate respondsToSelector:@selector(videoCapture:willFinishRecordingToFileURL:)]) {
            [self.delegate videoCapture:self willFinishRecordingToFileURL:self.fileURL];
        }
        self.recording = NO;
        __weak typeof(self) weakSelf = self;
        [self.writer finishRecordingWithCompletionHandler:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (completionHandler) {
                completionHandler(strongSelf.fileURL, nil);
            }
            if ([strongSelf.delegate respondsToSelector:@selector(videoCapture:didFinishRecordingToFileURL:)]) {
                [strongSelf.delegate videoCapture:self didFinishRecordingToFileURL:self.fileURL];
            }
            strongSelf.fileURL = nil;
            [self cleanWriter];
        }];
    } else {
        if (completionHandler) {
            NSError * error = [NSError errorWithDomain:@"没有开始录制" code:SGVideoCaptureErrorCodeRecording userInfo:nil];
            completionHandler(nil, error);
        }
    }
}

- (void)setupWriter
{
    self.writer = [[GPUImageMovieWriter alloc] initWithMovieURL:self.fileURL size:CGSizeMake(100, 100)];
    self.writer.encodingLiveVideo = YES;
    self.writer.shouldPassthroughAudio = YES;
    self.videoCamera.audioEncodingTarget = self.writer;
    [self tryAddWriterToFilter];
}

- (void)cleanWriter
{
    if (self.writer) {
        if ([self.filter.targets containsObject:self.writer]) {
            [self.filter removeTarget:self.writer];
        }
        self.writer = nil;
    }
}

- (void)tryAddWriterToFilter
{
    if (self.writer) {
        if (![self.filter.targets containsObject:self.writer]) {
            [self.filter addTarget:self.writer];
        }
    }
}

- (GPUImageVideoCamera *)videoCamera
{
    if(!_videoCamera) {
        _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
        _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        _videoCamera.horizontallyMirrorFrontFacingCamera = NO;
        NSString * filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"SGVideoCaptureTemp.mp4"];
        NSURL * url = [NSURL fileURLWithPath:filePath];
        _videoCamera.audioEncodingTarget = [[GPUImageMovieWriter alloc] initWithMovieURL:url size:CGSizeMake(1, 1)];
    }
    return _videoCamera;
}

- (UIView *)view
{
    return self.preview;
}

- (SGVideoCapturePreview *)preview
{
    if (!_preview) {
        _preview = [[SGVideoCapturePreview alloc] initWithFrame:CGRectZero];
    }
    return _preview;
}

- (SGCameraPosition)cameraPosition
{
    switch (self.videoCamera.cameraPosition) {
        case AVCaptureDevicePositionUnspecified:
        case AVCaptureDevicePositionFront:
            return SGCameraPositionFront;
        case AVCaptureDevicePositionBack:
            return SGCameraPositionBack;
    }
}

- (BOOL)setCameraPosition:(SGCameraPosition)cameraPosition error:(NSError **)error
{
    AVCaptureDevicePosition * position;
    switch (cameraPosition) {
        case SGCameraPositionFront:
            position = AVCaptureDevicePositionFront;
            break;
        case SGCameraPositionBack:
            position = AVCaptureDevicePositionBack;
            break;
    }
    
    if (position != self.videoCamera.cameraPosition) {
        [self.videoCamera rotateCamera];
    }
    
    return YES;
}

- (BOOL)torch
{
    return self.videoCamera.inputCamera.torchMode;
}

- (BOOL)torchEnable
{
    return self.videoCamera.inputCamera.torchAvailable;
}

- (BOOL)setTorch:(BOOL)torch error:(NSError *__autoreleasing *)error
{
    if (!self.videoCamera.captureSession) {
        NSError * err = [NSError errorWithDomain:@"摄像头不可用" code:SGVideoCaptureErrorCodeRunning userInfo:nil];
        * error = err;
        return NO;
    }
    
    NSError * err;
    AVCaptureSession * session = self.videoCamera.captureSession;
    [session beginConfiguration];
    if (self.videoCamera.inputCamera) {
        if (self.videoCamera.inputCamera.torchAvailable) {
            if ([self.videoCamera.inputCamera lockForConfiguration:&err]) {
                if (torch) {
                    self.videoCamera.inputCamera.torchMode = AVCaptureTorchModeOn;
                } else {
                    self.videoCamera.inputCamera.torchMode = AVCaptureTorchModeOff;
                }
                [self.videoCamera.inputCamera unlockForConfiguration];
            } else {
                err = [NSError errorWithDomain:@"获取摄像头配置信息失败" code:SGVideoCaptureErrorCodeRunning userInfo:nil];
            }
        } else {
            err = [NSError errorWithDomain:@"当前摄像头无法开启闪光灯" code:SGVideoCaptureErrorCodeRunning userInfo:nil];
        }
    } else {
        err = [NSError errorWithDomain:@"没有可用的摄像头输入源" code:SGVideoCaptureErrorCodeRunning userInfo:nil];
    }
    [session commitConfiguration];
    
    if (err) {
        * error = err;
        return NO;
    }
    
    return YES;
}

- (SGFocusMode)focusMode
{
    switch (self.videoCamera.inputCamera.focusMode) {
        case AVCaptureFocusModeLocked:
        case AVCaptureFocusModeAutoFocus:
            return SGFocusModeManual;
            break;
        case AVCaptureFocusModeContinuousAutoFocus:
            return SGFocusModeAutomatic;
    }
}

- (BOOL)focusModeAutomaticEnable
{
    return [self.videoCamera.inputCamera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus];
}

- (BOOL)focusModeManualEnable
{
    return [self.videoCamera.inputCamera isFocusModeSupported:AVCaptureFocusModeAutoFocus];
}

- (BOOL)setFocusMode:(SGFocusMode)focusMode error:(NSError **)error
{
    if (!self.videoCamera.captureSession) {
        NSError * err = [NSError errorWithDomain:@"摄像头不可用" code:SGVideoCaptureErrorCodeRunning userInfo:nil];
        * error = err;
        return NO;
    }
    
    NSError * err;
    if (self.videoCamera.inputCamera) {
        
        AVCaptureFocusMode * mode;
        switch (focusMode) {
            case SGFocusModeAutomatic:
                mode = AVCaptureFocusModeContinuousAutoFocus;
                break;
            case SGFocusModeManual:
                mode = AVCaptureFocusModeAutoFocus;
                break;
        }
        
        if ([self.videoCamera.inputCamera isFocusModeSupported:mode]) {
            if ([self.videoCamera.inputCamera lockForConfiguration:&err]) {
                self.videoCamera.inputCamera.focusMode = mode;
                [self.videoCamera.inputCamera unlockForConfiguration];
            } else {
                err = [NSError errorWithDomain:@"锁定摄像头配置信息失败" code:SGVideoCaptureErrorCodeRunning userInfo:nil];
            }
        } else {
            err = [NSError errorWithDomain:@"当前摄像头无法使用此对焦模式" code:SGVideoCaptureErrorCodeRunning userInfo:nil];
        }
        
    } else {
        err = [NSError errorWithDomain:@"没有可用的摄像头输入源" code:SGVideoCaptureErrorCodeRunning userInfo:nil];
    }
    
    if (err) {
        * error = err;
        return NO;
    }
    
    return YES;
}

- (BOOL)setFocusPointOfInterest:(CGPoint)focusPointOfInterest error:(NSError *__autoreleasing *)error
{
    if (!self.videoCamera.captureSession) {
        NSError * err = [NSError errorWithDomain:@"摄像头不可用" code:SGVideoCaptureErrorCodeRunning userInfo:nil];
        * error = err;
        return NO;
    }
    
    NSError * err;
    if (self.videoCamera.inputCamera) {
        if ([self.videoCamera.inputCamera isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            if (self.focusMode == SGFocusModeManual) {
                if([self.videoCamera.inputCamera lockForConfiguration:&err]) {
                    self.videoCamera.inputCamera.focusMode = AVCaptureFocusModeAutoFocus;
                    self.videoCamera.inputCamera.focusPointOfInterest = focusPointOfInterest;
                    [self.videoCamera.inputCamera unlockForConfiguration];
                } else {
                    err = [NSError errorWithDomain:@"锁定摄像头配置信息失败" code:SGVideoCaptureErrorCodeRunning userInfo:nil];
                }
            } else {
                err = [NSError errorWithDomain:@"仅手动对焦模式可使用此方法" code:SGVideoCaptureErrorCodeRunning userInfo:nil];
            }
        } else {
            err = [NSError errorWithDomain:@"当前摄像头无法使用此对焦模式" code:SGVideoCaptureErrorCodeRunning userInfo:nil];
        }
    } else {
        err = [NSError errorWithDomain:@"没有可用的摄像头输入源" code:SGVideoCaptureErrorCodeRunning userInfo:nil];
    }
    
    if (err) {
        * error = err;
        return NO;
    }
    
    return YES;
}

@end
