//
//  SGFormatFactory.m
//  SGMediaKit
//
//  Created by Single on 06/12/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "SGPlayerMacro.h"
#import "SGFormatFactory.h"
#import "SGFormat.h"

@interface SGFormatFactory () <SGFormatDelegate>

@property (nonatomic, assign) BOOL running;
@property (nonatomic, strong) SGFormat * format;
@property (nonatomic, copy) void (^progressHandler)(float);
@property (nonatomic, copy) void (^completionHandler)(NSError *);

@end

@implementation SGFormatFactory

+ (instancetype)formatFactory
{
    static SGFormatFactory * factory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        factory = [[self alloc] init];
    });
    return factory;
}

- (void)mpeg4FormatWithSourceFileURL:(NSURL *)sourceFileURL
                  destinationFileURL:(NSURL *)destinationFileURL
                     progressHandler:(void(^)(float progress))progressHandler
                   completionHandler:(void(^)(NSError * error))completionHandler
{
    [self startWithSourceFileURL:sourceFileURL
              destinationFileURL:destinationFileURL
                     qualityType:SGFormatQualityTypePassthrough
                        fileType:AVFileTypeMPEG4
                 progressHandler:progressHandler
               completionHandler:completionHandler];
}

- (void)startWithSourceFileURL:(NSURL *)sourceFileURL
            destinationFileURL:(NSURL *)destinationFileURL
                   qualityType:(SGFormatQualityType)qualityType
                      fileType:(NSString *)fileType
               progressHandler:(void (^)(float))progressHandler
             completionHandler:(void (^)(NSError *))completionHandler
{
    if (self.running) {
        if (completionHandler) {
            NSError * error = [NSError errorWithDomain:@"有任务正在进行..." code:1 userInfo:nil];
            completionHandler(error);
        }
        return;
    }
    
    [self setupWithSourceFileURL:sourceFileURL
              destinationFileURL:destinationFileURL
                     qualityType:qualityType
                        fileType:fileType
                 progressHandler:progressHandler
               completionHandler:completionHandler];
    [self start];
}

- (void)setupWithSourceFileURL:(NSURL *)sourceFileURL
            destinationFileURL:(NSURL *)destinationFileURL
                   qualityType:(SGFormatQualityType)qualityType
                      fileType:(NSString *)fileType
               progressHandler:(void (^)(float))progressHandler
             completionHandler:(void (^)(NSError *))completionHandler
{
    [self clean];
    
    self.progressHandler = progressHandler;
    self.completionHandler = completionHandler;
    
    self.format = [SGFormat formatWithSourceFileURL:sourceFileURL];
    self.format.destinationFileURL = destinationFileURL;
    self.format.qualityType = qualityType;
    self.format.fileType = fileType;
    self.format.delegate = self;
}

- (void)start
{
    [self.format start];
}

- (void)formatDidStart:(SGFormat *)format
{
    self.running = YES;
}

- (void)format:(SGFormat *)format didChangeProgross:(float)progress
{
    if (self.progressHandler) {
        self.progressHandler(progress);
    }
}

- (void)format:(SGFormat *)format didCompleteWithError:(NSError *)error
{
    self.running = NO;
    if (self.completionHandler) {
        self.completionHandler(error);
    }
    [self clean];
}

- (void)clean
{
    self.running = NO;
    [self cleanHandler];
    [self cleanFormat];
}

- (void)cleanHandler
{
    self.progressHandler = nil;
    self.completionHandler = nil;
}

- (void)cleanFormat
{
    self.format.delegate = nil;
    self.format = nil;
}

- (void)dealloc
{
    [self clean];
    SGPlayerLog(@"SGFormatFactory releas");
}

@end
