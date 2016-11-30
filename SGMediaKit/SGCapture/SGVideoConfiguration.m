//
//  SGVideoConfiguration.m
//  SGMediaKit
//
//  Created by Single on 28/11/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import "SGVideoConfiguration.h"
#import <AVFoundation/AVFoundation.h>

@implementation SGVideoConfiguration

+ (instancetype)defaultVideoConfiguration
{
    return [self defaultVideoConfigurationWithQuality:SGVideoQualityHigh];
}

+ (instancetype)defaultVideoConfigurationWithQuality:(SGVideoQuality)videoQuality
{
    return [[self alloc] initWithQuality:videoQuality];
}

- (instancetype)initWithQuality:(SGVideoQuality)videoQuality
{
    if (self = [super init]) {
        switch (videoQuality) {
            case SGVideoQualityLow:
            {
                self.size = SGVideoSize540p;
                self.frameRate = 15;
                self.bitRate = 800 * 1000;
            }
                break;
            case SGVideoQualityMedium:
            {
                self.size = SGVideoSize720p;
                self.frameRate = 24;
                self.bitRate = 1000 * 1000;
            }
                break;
            case SGVideoQualityHigh:
            {
                self.size = SGVideoSize1080p;
                self.frameRate = 30;
                self.bitRate = 1200 * 1000;
            }
                break;
        }
    }
    return self;
}

- (instancetype)init
{
    return [self initWithQuality:SGVideoQualityHigh];
}

- (CGSize)pixelsSize:(UIInterfaceOrientation)orientation
{
    CGSize size;
    switch (self.size) {
        case SGVideoSize540p:
            size = CGSizeMake(960, 540);
            break;
        case SGVideoSize720p:
            size = CGSizeMake(1280, 720);
            break;
        case SGVideoSize1080p:
            size = CGSizeMake(1920, 1080);
            break;
    }
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            size = CGSizeMake(size.height, size.width);
            break;
        default:
            break;
    }
    return size;
}

- (NSString *)sessionPreset
{
    switch (self.size) {
        case SGVideoSize540p:
            return AVCaptureSessionPresetiFrame960x540;
        case SGVideoSize720p:
            return AVCaptureSessionPreset1280x720;
        case SGVideoSize1080p:
            return AVCaptureSessionPreset1920x1080;
    }
}

@end
