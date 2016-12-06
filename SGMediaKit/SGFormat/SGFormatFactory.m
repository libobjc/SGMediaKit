//
//  SGFormatFactory.m
//  SGMediaKit
//
//  Created by Single on 06/12/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "SGFormatFactory.h"
#import "SGFormat.h"

@interface SGFormatFactory () <SGFormatDelegate>

@property (nonatomic, strong) SGFormat * format;

@property (nonatomic, assign) SGFormatQualityType qualityType;
@property (nonatomic, copy) void (^progressHandler)(float);
@property (nonatomic, copy) void (^completionHandler)(NSError *);

@end

@implementation SGFormatFactory

static SGFormatFactory * factory = nil;

+ (BOOL)isReady
{
    return factory == nil;
}

+ (void)mpeg4FormatWithSourceFileURL:(NSURL *)sourceFileURL
                  destinationFileURL:(NSURL *)destinationFileURL
                         qualityType:(SGFormatQualityType)qualityType
                     progressHandler:(void(^)(float progress))progressHandler
                   completionHandler:(void(^)(NSError * error))completionHandler
{
    if (![self isReady]) {
        if (completionHandler) {
            NSError * error = [NSError errorWithDomain:@"有任务正在进行..." code:1 userInfo:nil];
            completionHandler(error);
        }
        return;
    }
    
    factory = [[SGFormatFactory alloc] initWithSourceFileURL:sourceFileURL
                                      destinationFileURL:destinationFileURL
                                             qualityType:qualityType
                                                fileType:AVFileTypeMPEG4
                                         progressHandler:progressHandler
                                       completionHandler:completionHandler];
    [factory start];
}

- (instancetype)initWithSourceFileURL:(NSURL *)sourceFileURL
                   destinationFileURL:(NSURL *)destinationFileURL
                          qualityType:(SGFormatQualityType)qualityType
                             fileType:(NSString *)fileType
                      progressHandler:(void (^)(float))progressHandler
                    completionHandler:(void (^)(NSError *))completionHandler
{
    if (self = [super init])
    {
        self.qualityType = qualityType;
        self.progressHandler = progressHandler;
        self.completionHandler = completionHandler;
        
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
        
        self.format = [SGFormat formatWithSourceFileURL:sourceFileURL];
        self.format.destinationFileURL = destinationFileURL;
        self.format.quality = qualityString;
        self.format.fileType = fileType;
        self.format.delegate = self;
    }
    return self;
}

- (void)start
{
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
    if (factory) factory = nil;
}

- (void)cleanHandler
{
    self.progressHandler = nil;
    self.completionHandler = nil;
}

- (void)dealloc
{
    [self clean];
    NSLog(@"SGFormatFactory releas");
}

@end
