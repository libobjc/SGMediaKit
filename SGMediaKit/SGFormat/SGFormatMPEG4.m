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
@property (nonatomic, assign) SGFormatQualityType qualityType;
@property (nonatomic, copy) NSString * fileType;

@property (nonatomic, copy) void (^progressHandler)(float);
@property (nonatomic, copy) void (^completionHandler)(NSError *);

@end

@implementation SGFormatMPEG4

static SGFormatMPEG4 * mpeg4 = nil;

+ (void)formatWithSourceFileURL:(NSURL *)sourceFileURL
             destinationFileURL:(NSURL *)destinationFileURL
                    qualityType:(SGFormatQualityType)qualityType
                progressHandler:(void (^)(float))progressHandler
              completionHandler:(void (^)(NSError *))completionHandler
{
    mpeg4 = [[SGFormatMPEG4 alloc] initWithSourceFileURL:sourceFileURL
                                      destinationFileURL:destinationFileURL
                                             qualityType:qualityType
                                                fileType:AVFileTypeMPEG4
                                         progressHandler:progressHandler
                                       completionHandler:completionHandler];
    [mpeg4 start];
}

- (instancetype)initWithSourceFileURL:(NSURL *)sourceFileURL
                   destinationFileURL:(NSURL *)destinationFileURL
                          qualityType:(SGFormatQualityType)qualityType
                             fileType:(NSString *)fileType
                      progressHandler:(void (^)(float))progressHandler
                    completionHandler:(void (^)(NSError *))completionHandler
{
    if (self = [super init]) {
        self.sourceFileURL = sourceFileURL;
        self.destinationFileURL = destinationFileURL;
        self.qualityType = qualityType;
        self.fileType = fileType;
        self.progressHandler = progressHandler;
        self.completionHandler = completionHandler;
    }
    return self;
}

- (void)start
{
    NSString * qualityString;
    switch (self.qualityType) {
        case SGFormatQualityTypeLow:
            qualityString = AVAssetExportPresetLowQuality;
            break;
        case SGFormatQualityTypeMedium:
            qualityString = AVAssetExportPresetMediumQuality;
            break;
        case SGFormatQualityTypeHighest:
            qualityString = AVAssetExportPresetHighestQuality;
            break;
    }
    
    self.format = [SGFormat formatWithSourceFileURL:self.sourceFileURL];
    self.format.destinationFileURL = self.destinationFileURL;
    self.format.quality = qualityString;
    self.format.fileType = self.fileType;
    self.format.delegate = self;
    [self.format start];
}

- (void)format:(SGFormat *)format didChangeProgross:(float)progress
{
    if (self.progressHandler) {
        self.progressHandler(progress);
    }
}

- (void)format:(SGFormat *)format didCompleteWithError:(NSError *)error
{
    if (self.completionHandler) {
        self.completionHandler(error);
    }
    [self clean];
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
