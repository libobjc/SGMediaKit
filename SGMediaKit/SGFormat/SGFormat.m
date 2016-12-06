//
//  SGFormat.m
//  SGMediaKit
//
//  Created by Single on 06/12/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import "SGFormat.h"
#import <AVFoundation/AVFoundation.h>

@interface SGFormat ()

@property (nonatomic, copy) NSURL * sourceFileURL;
@property (nonatomic, assign) float progress;

@property (nonatomic, strong) AVURLAsset * sourceAsset;
@property (nonatomic, strong) AVAssetExportSession * exportSession;

@property (nonatomic, strong) NSTimer * progressTimer;

@end

@implementation SGFormat

+ (instancetype)formatWithSourceFileURL:(NSURL *)sourceFileURL
{
    return [[self alloc] initWithSourceFileURL:sourceFileURL];
}

- (instancetype)initWithSourceFileURL:(NSURL *)sourceFileURL
{
    if (self = [super init]) {
        self.sourceFileURL = sourceFileURL;
        self.quality = AVAssetExportPresetMediumQuality;
        self.fileType = AVFileTypeQuickTimeMovie;
    }
    return self;
}

- (void)start
{
    if (!self.sourceFileURL.isFileURL) {
        [self completeWithError:[NSError errorWithDomain:@"无效的 sourceFileURL" code:1 userInfo:nil]];
        return;
    }
    if (!self.destinationFileURL.isFileURL) {
        [self completeWithError:[NSError errorWithDomain:@"无效的 destinationFileURL" code:1 userInfo:nil]];
        return;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.destinationFileURL.path]) {
        [self completeWithError:[NSError errorWithDomain:@"destinationFileURL 文件已经存在" code:1 userInfo:nil]];
        return;
    }
    
    self.sourceAsset = [AVURLAsset assetWithURL:self.sourceFileURL];
    self.exportSession = [AVAssetExportSession exportSessionWithAsset:self.sourceAsset presetName:self.quality];
    self.exportSession.shouldOptimizeForNetworkUse = YES;
    self.exportSession.outputFileType = self.fileType;
    self.exportSession.outputURL = self.destinationFileURL;
    self.exportSession.timeRange = CMTimeRangeMake(kCMTimeZero, self.sourceAsset.duration);
    
    if ([self.delegate respondsToSelector:@selector(formatDidStart:)]) {
        [self.delegate formatDidStart:self];
    }
    [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
        [self completeWithError:nil];
    }];
    
    self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(fetchProgress) userInfo:nil repeats:YES];
    self.progressTimer.fireDate = [NSDate distantPast];
}

- (void)completeWithError:(NSError *)error
{
    [self fetchProgress];
    if (self.progressTimer) {
        self.progressTimer.fireDate = [NSDate distantFuture];
        [self.progressTimer invalidate];
        self.progressTimer = nil;
    }
    if ([self.delegate respondsToSelector:@selector(format:didCompleteWithError:)]) {
        [self.delegate format:self didCompleteWithError:error];
    }
}

- (void)fetchProgress
{
    self.progress = self.exportSession.progress;
}

- (void)setProgress:(float)progress
{
    if (_progress != progress) {
        _progress = progress;
        if ([self.delegate respondsToSelector:@selector(format:didChangeProgross:)]) {
            [self.delegate format:self didChangeProgross:progress];
        }
    }
}

- (void)dealloc
{
    NSLog(@"SGFormat releas");
}

@end
