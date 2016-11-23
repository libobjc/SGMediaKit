//
//  SGVideoCapture.m
//  SGMediaKit
//
//  Created by Single on 23/11/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import "SGVideoCapture.h"

@interface SGVideoCapture ()

@property (nonatomic, assign) BOOL running;
@property (nonatomic, strong) GPUImageVideoCamera * videoCamera;
@property (nonatomic, strong) GPUImageFilter * filter;

@end

@implementation SGVideoCapture

@synthesize view = _view;

- (void)reloadFilter
{
    [self.filter removeTarget:self.view.gpuImageView];
    if ([self.delegate respondsToSelector:@selector(filterInVideoCapture:)]) {
        self.filter = [self.delegate filterInVideoCapture:self];
    }
    if (!self.filter) {
        self.filter = [[GPUImageFilter alloc] init];
    }
    [self.filter addTarget:self.view.gpuImageView];
    [self.videoCamera addTarget:self.filter];
}

- (void)startRunning
{
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

- (void)stopRunning
{
    if ([self.delegate respondsToSelector:@selector(videoCaptureWillStopRunning:)]) {
        [self.delegate videoCaptureWillStopRunning:self];
    }
    self.running = NO;
    [self.videoCamera stopCameraCapture];
    if ([self.delegate respondsToSelector:@selector(videoCaptureDidStopRunning:)]) {
        [self.delegate videoCaptureDidStopRunning:self];
    }
}

- (GPUImageVideoCamera *)videoCamera
{
    if(!_videoCamera) {
        _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
        _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        _videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    }
    return _videoCamera;
}

- (SGVideoCaptureView *)view
{
    if (!_view) {
        _view = [[SGVideoCaptureView alloc] initWithFrame:CGRectZero];
    }
    return _view;
}

@end
