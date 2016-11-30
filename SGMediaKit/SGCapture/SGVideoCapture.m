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

NSString * const SGVideoCaptureErrorNameNone = @"no error";
NSString * const SGVideoCaptureErrorNameCameraDisabled = @"摄像头不可用";
NSString * const SGVideoCaptureErrorNmaeCameraPositionDisable = @"无法切换摄像头";
NSString * const SGVideoCaptureErrorNameLockCameraFailure = @"锁定摄像头配置信息失败";
NSString * const SGVideoCaptureErrorNameTorchDisable = @"当前摄像头无法开启闪光灯";
NSString * const SGVideoCaptureErrorNameFocusDisable = @"当前摄像头无法使用此对焦模式";
NSString * const SGVideoCaptureErrorNameFocusModeUnsupported = @"仅手动对焦模式可使用此方法";
NSString * const SGVideoCaptureErrorNameExposureDisable = @"当前摄像头无法使用此曝光模式";
NSString * const SGVideoCaptureErrorNameExposureModeUnsupported = @"仅手动曝光模式可使用此方法";
NSString * const SGVideoCaptureErrorNameHasStartRecord = @"已经在在录制";
NSString * const SGVideoCaptureErrorNameFileURLInvalid = @"fileURL 不是可用的文件URL";
NSString * const SGVideoCaptureErrorNameFileExists = @"文件已经存在";
NSString * const SGVideoCaptureErrorNameFileDirectoryInexistence = @"目标文件夹不存在";
NSString * const SGVideoCaptureErrorNameRecordCanceled = @"主动取消";

@interface SGVideoCapture ()

@property (nonatomic, strong) SGVideoConfiguration * videoConfiguration;

@property (nonatomic, assign) BOOL running;
@property (nonatomic, assign) BOOL recording;
@property (nonatomic, strong) GPUImageVideoCamera * videoCamera;
@property (nonatomic, strong) GPUImageFilter * filter;
@property (nonatomic, strong) GPUImageMovieWriter * writer;
@property (nonatomic, copy) NSURL * fileURL;
@property (nonatomic, copy) void(^recordingFinishedHandler)(NSURL * fileURL, NSError * error);
@property (nonatomic, strong) SGVideoCapturePreview * preview;

@end

@implementation SGVideoCapture

+ (BOOL)canCapture
{
    return [self cameraPositionFrontEnable] || [self cameraPositionBackEnable];
}

+ (BOOL)cameraPositionFrontEnable
{
    return [self cammeraPositionEnableCheck:AVCaptureDevicePositionFront];
}

+ (BOOL)cameraPositionBackEnable
{
    return [self cammeraPositionEnableCheck:AVCaptureDevicePositionBack];
}

+ (BOOL)cammeraPositionEnableCheck:(AVCaptureDevicePosition)position
{
    NSArray * devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice * device in devices) {
        if ([device position] == position) return YES;
    }
    return NO;
}

- (instancetype)initWithVideoConfiguration:(SGVideoConfiguration *)videoConfiguration
{
    if (self = [super init]) {
        self.videoConfiguration = videoConfiguration;
        [self setup];
    }
    return self;
}

- (void)setup
{
    // video camera
    AVCaptureDevicePosition position = AVCaptureDevicePositionBack;
    if (!self.cameraPositionBackEnable) {
        if (self.cameraPositionFrontEnable) {
            position = AVCaptureDevicePositionFront;
        }
    }
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:position];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    NSString * filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"SGVideoCaptureTemp.mp4"];
    NSURL * url = [NSURL fileURLWithPath:filePath];
    self.videoCamera.audioEncodingTarget = [[GPUImageMovieWriter alloc] initWithMovieURL:url size:CGSizeMake(1, 1)];
    
    // notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadOrientation) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)didEnterBackground:(NSNotification *)notification
{
    if (self.running) {
        [self.videoCamera pauseCameraCapture];
    }
    if (self.recording) {
        if ([self.delegate respondsToSelector:@selector(videoCapture:needForceFinishRecordingForFileURL:)]) {
            [self.delegate videoCapture:self needForceFinishRecordingForFileURL:self.fileURL];
        }
        if (self.recording) {
            [self finishRecording];
        }
    }
}

- (void)willEnterForeground:(NSNotification *)notification
{
    if (self.running) {
        [self.videoCamera resumeCameraCapture];
    }
}

- (void)updateMetadataCallBack
{
    if ([self.delegate respondsToSelector:@selector(videoCaptureUpdateMetadata:)]) {
        [self.delegate videoCaptureUpdateMetadata:self];
    }
}

- (void)reloadOrientation
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (self.videoCamera.outputImageOrientation != orientation && !self.recording) {
        self.videoCamera.outputImageOrientation = orientation;
    }
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
        [self updateMetadataCallBack];
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
        [self updateMetadataCallBack];
    }
}

- (BOOL)startRecordingWithFileURL:(NSURL *)fileURL error:(NSError **)error finishedHandler:(void (^)(NSURL *, NSError *))finishedHandler
{
    if (!self.videoCamera.captureSession) {
        NSError * err = [NSError errorWithDomain:SGVideoCaptureErrorNameCameraDisabled code:SGVideoCaptureErrorCodeCameraDisable userInfo:nil];
        * error = err;
        return NO;
    }
    
    if (self.recording) {
        NSError * err = [NSError errorWithDomain:SGVideoCaptureErrorNameHasStartRecord code:SGVideoCaptureErrorCodeHasStartRecord userInfo:nil];
        * error = err;
        return NO;
    }
    if (!fileURL.isFileURL) {
        NSError * err = [NSError errorWithDomain:SGVideoCaptureErrorNameFileURLInvalid code:SGVideoCaptureErrorCodeFileURLInvalid userInfo:nil];
        * error = err;
        return NO;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
        NSError * err = [NSError errorWithDomain:SGVideoCaptureErrorNameFileExists code:SGVideoCaptureErrorCodeFileExists userInfo:nil];
        * error = err;
        return NO;
    }
    static NSString * key = @"*&^%$#@!single";
    NSString * tempPath = [fileURL.path stringByAppendingPathComponent:key];
    NSString * pathDirectory = [tempPath stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/%@", fileURL.lastPathComponent, key] withString:@""];
    if (![[NSFileManager defaultManager] fileExistsAtPath:pathDirectory]) {
        NSError * err = [NSError errorWithDomain:SGVideoCaptureErrorNameFileDirectoryInexistence code:SGVideoCaptureErrorCodeFileDirectoryInexistence userInfo:nil];
        * error = err;
        return NO;
    }
    
    self.fileURL = fileURL;
    self.recordingFinishedHandler = finishedHandler;
    [self setupWriter];
    if ([self.delegate respondsToSelector:@selector(videoCapture:willStartRecordingfToFileURL:)]) {
        [self.delegate videoCapture:self willStartRecordingfToFileURL:fileURL];
    }
    self.recording = YES;
    [self.writer startRecording];
    if ([self.delegate respondsToSelector:@selector(videoCapture:didStartRecordingToFileURL:)]) {
        [self.delegate videoCapture:self didStartRecordingToFileURL:fileURL];
    }
    [self updateMetadataCallBack];
    return YES;
}

- (void)finishRecording
{
    if (self.recording) {
        if ([self.delegate respondsToSelector:@selector(videoCapture:willFinishRecordingToFileURL:)]) {
            [self.delegate videoCapture:self willFinishRecordingToFileURL:self.fileURL];
        }
        self.recording = NO;
        __weak typeof(self) weakSelf = self;
        [self.writer finishRecordingWithCompletionHandler:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if ([strongSelf.delegate respondsToSelector:@selector(videoCapture:didFinishRecordingToFileURL:)]) {
                [strongSelf.delegate videoCapture:self didFinishRecordingToFileURL:self.fileURL];
            }
            if (self.recordingFinishedHandler) {
                self.recordingFinishedHandler(strongSelf.fileURL, nil);
            }
            [strongSelf reloadOrientation];
            strongSelf.fileURL = nil;
            strongSelf.recordingFinishedHandler = nil;
            [self cleanWriter];
            [self updateMetadataCallBack];
        }];
    }
}

- (void)cancelRecording
{
    if (self.recording) {
        if ([self.delegate respondsToSelector:@selector(videoCapture:willCancelRecordingToFileURL:)]) {
            [self.delegate videoCapture:self willCancelRecordingToFileURL:self.fileURL];
        }
        self.recording = NO;
        [self.writer cancelRecording];
        if ([self.delegate respondsToSelector:@selector(videoCapture:didCancelRecordingToFileURL:)]) {
            [self.delegate videoCapture:self didCancelRecordingToFileURL:self.fileURL];
        }
        if (self.recordingFinishedHandler) {
            NSError * error = [NSError errorWithDomain:SGVideoCaptureErrorNameRecordCanceled code:SGVideoCaptureErrorCodeRecordCanceled userInfo:nil];
            self.recordingFinishedHandler(self.fileURL, error);
        }
        [self reloadOrientation];
        self.fileURL = nil;
        self.recordingFinishedHandler = nil;
        [self cleanWriter];
        [self updateMetadataCallBack];
    }
}

- (void)setupWriter
{
    CGSize size = CGSizeMake(720, 1280);
    switch ([UIApplication sharedApplication].statusBarOrientation) {
        case UIInterfaceOrientationLandscapeRight:
        case UIInterfaceOrientationLandscapeLeft:
            size = CGSizeMake(size.height, size.width);
            break;
        default:
            break;
    }
    
    self.writer = [[GPUImageMovieWriter alloc] initWithMovieURL:self.fileURL size:size];
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

- (void)setDelegate:(id<SGVideoCaptureDelegate>)delegate
{
    if (_delegate != delegate) {
        _delegate = delegate;
        [self updateMetadataCallBack];
    }
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

- (void)setMirror:(BOOL)mirror
{
    if (_mirror != mirror) {
        _mirror = mirror;
        self.videoCamera.horizontallyMirrorFrontFacingCamera = mirror;
        [self updateMetadataCallBack];
    }
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

- (BOOL)cameraPositionFrontEnable
{
    return [self.class cameraPositionFrontEnable];
}

- (BOOL)cameraPositionBackEnable
{
    return [self.class cameraPositionBackEnable];
}

- (BOOL)cammeraPositionEnableCheck:(AVCaptureDevicePosition)position
{
    NSArray * devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice * device in devices)
    {
        if ([device position] == position)
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL)setCameraPosition:(SGCameraPosition)cameraPosition error:(NSError **)error
{
    AVCaptureDevicePosition position;
    switch (cameraPosition) {
        case SGCameraPositionFront:
            position = AVCaptureDevicePositionFront;
            break;
        case SGCameraPositionBack:
            position = AVCaptureDevicePositionBack;
            break;
    }
    
    if (![self cammeraPositionEnableCheck:position]) {
        NSError * err = [NSError errorWithDomain:SGVideoCaptureErrorNmaeCameraPositionDisable code:SGVideoCaptureErrorCodeCameraPositionDisable userInfo:nil];
        * error = err;
        return NO;
    }
    
    if (position != self.videoCamera.cameraPosition) {
        [self.videoCamera rotateCamera];
        if (position == self.videoCamera.cameraPosition) {
            [self updateMetadataCallBack];
        } else {
            NSError * err = [NSError errorWithDomain:SGVideoCaptureErrorNmaeCameraPositionDisable code:SGVideoCaptureErrorCodeCameraPositionDisable userInfo:nil];
            * error = err;
            return NO;
        }
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
        NSError * err = [NSError errorWithDomain:SGVideoCaptureErrorNameCameraDisabled code:SGVideoCaptureErrorCodeCameraDisable userInfo:nil];
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
                [self updateMetadataCallBack];
            } else {
                err = [NSError errorWithDomain:SGVideoCaptureErrorNameLockCameraFailure code:SGVideoCaptureErrorCodeLockCameraFailure userInfo:nil];
            }
        } else {
            err = [NSError errorWithDomain:SGVideoCaptureErrorNameTorchDisable code:SGVideoCaptureErrorCodeTorchDisable userInfo:nil];
        }
    } else {
        err = [NSError errorWithDomain:SGVideoCaptureErrorNameCameraDisabled code:SGVideoCaptureErrorCodeCameraDisable userInfo:nil];
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

- (BOOL)focusModeEnable
{
    BOOL manual = [self.videoCamera.inputCamera isFocusModeSupported:AVCaptureFocusModeAutoFocus];
    BOOL automatic = [self.videoCamera.inputCamera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus];
    return manual && automatic;
}

- (BOOL)setFocusMode:(SGFocusMode)focusMode error:(NSError **)error
{
    if (!self.videoCamera.captureSession) {
        NSError * err = [NSError errorWithDomain:SGVideoCaptureErrorNameCameraDisabled code:SGVideoCaptureErrorCodeCameraDisable userInfo:nil];
        * error = err;
        return NO;
    }
    
    NSError * err;
    if (self.videoCamera.inputCamera) {
        
        AVCaptureFocusMode mode;
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
                [self updateMetadataCallBack];
            } else {
                err = [NSError errorWithDomain:SGVideoCaptureErrorNameLockCameraFailure code:SGVideoCaptureErrorCodeLockCameraFailure userInfo:nil];
            }
        } else {
            err = [NSError errorWithDomain:SGVideoCaptureErrorNameFocusDisable code:SGVideoCaptureErrorCodeFocusDisable userInfo:nil];
        }
        
    } else {
        err = [NSError errorWithDomain:SGVideoCaptureErrorNameCameraDisabled code:SGVideoCaptureErrorCodeCameraDisable userInfo:nil];
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
        NSError * err = [NSError errorWithDomain:SGVideoCaptureErrorNameCameraDisabled code:SGVideoCaptureErrorCodeCameraDisable userInfo:nil];
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
                    err = [NSError errorWithDomain:SGVideoCaptureErrorNameLockCameraFailure code:SGVideoCaptureErrorCodeLockCameraFailure userInfo:nil];
                }
            } else {
                err = [NSError errorWithDomain:SGVideoCaptureErrorNameFocusModeUnsupported code:SGVideoCaptureErrorCodeFocusModeUnsupported userInfo:nil];
            }
        } else {
            err = [NSError errorWithDomain:SGVideoCaptureErrorNameFocusDisable code:SGVideoCaptureErrorCodeFocusDisable userInfo:nil];
        }
    } else {
        err = [NSError errorWithDomain:SGVideoCaptureErrorNameCameraDisabled code:SGVideoCaptureErrorCodeCameraDisable userInfo:nil];
    }
    
    if (err) {
        * error = err;
        return NO;
    }
    
    return YES;
}

- (SGExposureMode)exposureMode
{
    switch (self.videoCamera.inputCamera.exposureMode) {
        case AVCaptureExposureModeLocked:
        case AVCaptureExposureModeAutoExpose:
        case AVCaptureExposureModeCustom:
            return SGExposureModeManual;
        case AVCaptureExposureModeContinuousAutoExposure:
            return SGExposureModeAutomatic;
    }
}

- (BOOL)exposureModeEnable
{
    BOOL manual = [self.videoCamera.inputCamera isExposureModeSupported:AVCaptureExposureModeAutoExpose];
    BOOL automatic = [self.videoCamera.inputCamera isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure];
    return manual && automatic;
}

- (BOOL)setExposureMode:(SGExposureMode)exposureMode error:(NSError *__autoreleasing *)error
{
    if (!self.videoCamera.captureSession) {
        NSError * err = [NSError errorWithDomain:SGVideoCaptureErrorNameCameraDisabled code:SGVideoCaptureErrorCodeCameraDisable userInfo:nil];
        * error = err;
        return NO;
    }
    
    NSError * err;
    if (self.videoCamera.inputCamera) {
        
        AVCaptureExposureMode mode;
        switch (exposureMode) {
            case SGExposureModeAutomatic:
                mode = AVCaptureExposureModeContinuousAutoExposure;
                break;
            case SGExposureModeManual:
                mode = AVCaptureExposureModeAutoExpose;
                break;
        }
        
        if ([self.videoCamera.inputCamera isExposureModeSupported:mode]) {
            if ([self.videoCamera.inputCamera lockForConfiguration:&err]) {
                self.videoCamera.inputCamera.exposureMode = mode;
                [self.videoCamera.inputCamera unlockForConfiguration];
                [self updateMetadataCallBack];
            } else {
                err = [NSError errorWithDomain:SGVideoCaptureErrorNameLockCameraFailure code:SGVideoCaptureErrorCodeLockCameraFailure userInfo:nil];
            }
        } else {
            err = [NSError errorWithDomain:SGVideoCaptureErrorNameExposureDisable code:SGVideoCaptureErrorCodeExposureDisable userInfo:nil];
        }
        
    } else {
        err = [NSError errorWithDomain:SGVideoCaptureErrorNameCameraDisabled code:SGVideoCaptureErrorCodeCameraDisable userInfo:nil];
    }
    
    if (err) {
        * error = err;
        return NO;
    }
    
    return YES;
}

- (BOOL)setExposurePointOfInterest:(CGPoint)exposurePointOfInterest error:(NSError *__autoreleasing *)error
{
    if (!self.videoCamera.captureSession) {
        NSError * err = [NSError errorWithDomain:SGVideoCaptureErrorNameCameraDisabled code:SGVideoCaptureErrorCodeCameraDisable userInfo:nil];
        * error = err;
        return NO;
    }
    
    NSError * err;
    if (self.videoCamera.inputCamera) {
        if ([self.videoCamera.inputCamera isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
            if (self.exposureMode == SGFocusModeManual) {
                if([self.videoCamera.inputCamera lockForConfiguration:&err]) {
                    self.videoCamera.inputCamera.exposureMode = AVCaptureExposureModeAutoExpose;
                    self.videoCamera.inputCamera.exposurePointOfInterest = exposurePointOfInterest;
                    [self.videoCamera.inputCamera unlockForConfiguration];
                } else {
                    err = [NSError errorWithDomain:SGVideoCaptureErrorNameLockCameraFailure code:SGVideoCaptureErrorCodeLockCameraFailure userInfo:nil];
                }
            } else {
                err = [NSError errorWithDomain:SGVideoCaptureErrorNameExposureModeUnsupported code:SGVideoCaptureErrorCodeExposureModeUnsupported userInfo:nil];
            }
        } else {
            err = [NSError errorWithDomain:SGVideoCaptureErrorNameExposureDisable code:SGVideoCaptureErrorCodeExposureDisable userInfo:nil];
        }
    } else {
        err = [NSError errorWithDomain:SGVideoCaptureErrorNameCameraDisabled code:SGVideoCaptureErrorCodeCameraDisable userInfo:nil];
    }
    
    if (err) {
        * error = err;
        return NO;
    }
    
    return YES;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
