//
//  SGVideoRecord.m
//  SGMediaKit
//
//  Created by Single on 23/11/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import "SGVideoRecord.h"
#import "SGVideoCapture.h";
#import "SGVideoCaptureFilter.h"

@interface SGVideoRecord () <SGVideoCaptureDelegate>

@property (nonatomic, strong) SGVideoCapture * videoCapture;
@property (nonatomic, strong) GPUImageFilter * filter;

@end

@implementation SGVideoRecord

- (instancetype)init
{
    if (self = [super init]) {
        
    }
    return self;
}

- (void)startRecording
{
    
}

- (void)stopRecording
{
    
}

- (GPUImageFilter *)filterInVideoCapture:(SGVideoCapture *)videoCapture
{
    return self.filter;
}

- (SGVideoCapture *)videoCapture
{
    if (!_videoCapture) {
        _videoCapture = [[SGVideoCapture alloc] init];
        _videoCapture.delegate = self;
        [_videoCapture startRunning];
    }
    return _videoCapture;
}

- (GPUImageFilter *)filter
{
    if (!_filter) {
        _filter = [SGVideoCaptureFilter defaultFilter];
    }
    return _filter;
}

- (UIView *)view
{
    return self.videoCapture.view;
}

- (void)dealloc
{
    [self.videoCapture stopRunning];
}

@end
