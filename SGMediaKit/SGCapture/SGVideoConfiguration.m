//
//  SGVideoConfiguration.m
//  SGMediaKit
//
//  Created by Single on 28/11/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import "SGVideoConfiguration.h"
#import <AVFoundation/AVFoundation.h>

@interface SGVideoConfiguration ()

@property (nonatomic, assign) SGVideoSize size;
@property (nonatomic, assign) NSUInteger frameRate;
@property (nonatomic, assign) NSUInteger bitRate;

@end

@implementation SGVideoConfiguration

+ (instancetype)defaultVideoConfiguration
{
    return [self defaultVideoConfigurationWithQuality:SGVideoQualityHigh];
}

+ (instancetype)defaultVideoConfigurationWithQuality:(SGVideoQuality)videoQuality
{
    return [[self alloc] initWithQuality:videoQuality];
}

- (instancetype)init
{
    return [self initWithQuality:SGVideoQualityHigh];
}

- (instancetype)initWithQuality:(SGVideoQuality)videoQuality
{
    if (self = [super init]) {
        videoQuality = [self checkSupportVideoQuality:videoQuality];
        switch (videoQuality) {
            case SGVideoQualityLow:
            {
                self.size = SGVideoSize640X480;
                self.frameRate = 15;
                self.bitRate = 500 * 1000;
            }
                break;
            case SGVideoQualityMedium:
            {
                self.size = SGVideoSize960x540;
                self.frameRate = 24;
                self.bitRate = 800 * 1000;
            }
                break;
            case SGVideoQualityHigh:
            {
                self.size = SGVideoSize1280x720;
                self.frameRate = 30;
                self.bitRate = 1000 * 1000;
            }
                break;
            case SGVideoQualityUltra:
            {
                self.size = SGVideoSize1920x1080;
                self.frameRate = 30;
                self.bitRate = 1200 * 1000;
            }
                break;
        }
    }
    return self;
}

- (SGVideoQuality)checkSupportVideoQuality:(SGVideoQuality)quality
{
    AVCaptureSession * session = [[AVCaptureSession alloc] init];
    AVCaptureDevice * camera;
    NSArray * devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice * device in devices){
        if ([device position] == AVCaptureDevicePositionFront){
            camera = device;
        }
    }
    AVCaptureDeviceInput * input = [[AVCaptureDeviceInput alloc] initWithDevice:camera error:nil];
    
    if (!input) return quality;
    if (![session canAddInput:input]) return quality;
    
    [session addInput:input];
    
    switch (quality) {
        case SGVideoQualityUltra:
        {
            if ([session canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
                return SGVideoQualityUltra;
            }
        }
        case SGVideoQualityHigh:
        {
            if ([session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
                return SGVideoQualityHigh;
            }
        }
        case SGVideoQualityMedium:
        {
            if ([session canSetSessionPreset:AVCaptureSessionPresetiFrame960x540]) {
                return SGVideoQualityMedium;
            }
        }
        case SGVideoQualityLow:
        {
            if ([session canSetSessionPreset:AVCaptureSessionPreset640x480]) {
                return SGVideoQualityLow;
            }
        }
    }
    return quality;
}

#if SGPLATFORM_TARGET_OS_MAC_OR_TV
- (CGSize)pixelsSize
{
    CGSize size;
    switch (self.size) {
        case SGVideoSize640X480:
            size = CGSizeMake(640, 480);
            break;
        case SGVideoSize960x540:
            size = CGSizeMake(960, 540);
            break;
        case SGVideoSize1280x720:
            size = CGSizeMake(1280, 720);
            break;
        case SGVideoSize1920x1080:
            size = CGSizeMake(1920, 1080);
            break;
    }
    return size;
}
#elif SGPLATFORM_TARGET_OS_IPHONE
- (CGSize)pixelsSize:(UIInterfaceOrientation)orientation
{
    CGSize size;
    switch (self.size) {
        case SGVideoSize640X480:
            size = CGSizeMake(640, 480);
            break;
        case SGVideoSize960x540:
            size = CGSizeMake(960, 540);
            break;
        case SGVideoSize1280x720:
            size = CGSizeMake(1280, 720);
            break;
        case SGVideoSize1920x1080:
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
#endif

- (NSString *)sessionPreset
{
    switch (self.size) {
        case SGVideoSize640X480:
            return AVCaptureSessionPreset640x480;
        case SGVideoSize960x540:
            return AVCaptureSessionPresetiFrame960x540;
        case SGVideoSize1280x720:
            return AVCaptureSessionPreset1280x720;
        case SGVideoSize1920x1080:
            return AVCaptureSessionPreset1920x1080;
    }
}

@end
