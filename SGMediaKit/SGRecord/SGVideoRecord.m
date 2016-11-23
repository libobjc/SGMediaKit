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
#import "SGVideoCaptureWriter.h"

@interface SGVideoRecord () <SGVideoCaptureDelegate>

@property (nonatomic, strong) SGVideoCapture * videoCapture;
@property (nonatomic, strong) GPUImageFilter * filter;
@property (nonatomic, strong) GPUImageMovieWriter * videoWriter;
@property (nonatomic, copy) NSURL * videoURL;

@end

@implementation SGVideoRecord

+ (NSURL *)videoSaveDirectory
{
    static NSURL * url = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString * path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"SGMediaKitFile/SGMediaRecordFile"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }
        url = [NSURL fileURLWithPath:path isDirectory:YES];
    });
    return url;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self setupVideoWriter];
    }
    return self;
}

- (void)setupVideoWriter
{
    [self.filter removeTarget:self.videoWriter];
    
    NSString * fileName = [NSString stringWithFormat:@"%ld.mp4", (NSInteger)[NSDate date].timeIntervalSince1970];
    NSString * filePath = [[self.class videoSaveDirectory].relativePath stringByAppendingPathComponent:fileName];
    self.videoURL = [NSURL fileURLWithPath:filePath isDirectory:NO];
    self.videoWriter = [SGVideoCaptureWriter defaultWriterWithURL:self.videoURL size:CGSizeMake(380, 640)];
    self.videoCapture.videoCamera.audioEncodingTarget = self.videoWriter;
    [self.filter addTarget:self.videoWriter];
}

- (void)startRecording
{
    [self.videoWriter startRecording];
}

- (void)finishRecordingWithCompletionHandler:(void (^)(NSURL *))handler
{
    [self.videoWriter finishRecordingWithCompletionHandler:^{
        if (handler) {
            handler(self.videoURL);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupVideoWriter];
        });
    }];
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
        if (self.videoWriter) {
            [_filter addTarget:self.videoWriter];
        }
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
