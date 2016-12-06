//
//  SGFormatMPEG4.m
//  SGMediaKit
//
//  Created by Single on 06/12/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import "SGFormatMPEG4.h"
#import "SGFormat.h"
#import <AVFoundation/AVFoundation.h>

@interface SGFormatMPEG4 () <SGFormatDelegate>

@property (nonatomic, strong) SGFormat * format;

@property (nonatomic, copy) NSURL * sourceFileURL;
@property (nonatomic, copy) NSURL * destinationFileURL;
@property (nonatomic, assign) SGFormatQuality quality;

@property (nonatomic, copy) void (^progressHandler)(float);
@property (nonatomic, copy) void (^completionHandler)(NSError *);

@end

@implementation SGFormatMPEG4

static SGFormatMPEG4 * mpeg4 = nil;

+ (void)formatWithSourceFileURL:(NSURL *)sourceFileURL destinationFileURL:(NSURL *)destinationFileURL quality:(SGFormatQuality)quality progressHandler:(void (^)(float))progressHandler completionHandler:(void (^)(NSError *))completionHandler
{
    mpeg4 = [[SGFormatMPEG4 alloc] initWithSourceFileURL:sourceFileURL destinationFileURL:destinationFileURL quality:quality progressHandler:progressHandler completionHandler:completionHandler];
    [mpeg4 start];
}

- (instancetype)initWithSourceFileURL:(NSURL *)sourceFileURL destinationFileURL:(NSURL *)destinationFileURL quality:(SGFormatQuality)quality progressHandler:(void (^)(float))progressHandler completionHandler:(void (^)(NSError *))completionHandler
{
    if (self = [super init]) {
        self.sourceFileURL = sourceFileURL;
        self.destinationFileURL = destinationFileURL;
        self.quality = quality;
        self.progressHandler = progressHandler;
        self.completionHandler = completionHandler;
    }
    return self;
}

- (void)start
{
    self.format = [SGFormat formatWithSourceFileURL:self.sourceFileURL];
    self.format.destinationFileURL = self.destinationFileURL;
    switch (self.quality) {
        case SGFormatQualityLow:
            self.format.quality = AVAssetExportPresetLowQuality;
            break;
        case SGFormatQualityMedium:
            self.format.quality = AVAssetExportPresetMediumQuality;
            break;
        case SGFormatQualityHighest:
            self.format.quality = AVAssetExportPresetHighestQuality;
            break;
    }
    self.format.fileType = AVFileTypeMPEG4;
    self.format.delegate = self;
    [self.format start];
}

- (void)formatDidStart:(SGFormat *)format
{
    NSLog(@"开始转换");
}

- (void)format:(SGFormat *)format didChangeProgross:(float)progress
{
    if (self.progressHandler) {
        self.progressHandler(progress);
    }
    NSLog(@"转换进度 : %f", progress);
}

- (void)format:(SGFormat *)format didCompleteWithError:(NSError *)error
{
    if (self.completionHandler) {
        self.completionHandler(error);
    }
    [self clean];
    if (error) {
        NSLog(@"转换失败 : %@", error);
    } else {
        NSLog(@"转换完成");
    }
}

- (void)clean
{
    [self cleanHandler];
    if (mpeg4) {
        mpeg4 = nil;
    }
}

- (void)cleanHandler
{
    self.progressHandler = nil;
    self.completionHandler = nil;
}

- (void)dealloc
{
    [self clean];
    NSLog(@"SGFormatMPEG4 releas");
}

@end
