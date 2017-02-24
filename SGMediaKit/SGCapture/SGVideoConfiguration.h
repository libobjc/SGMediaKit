//
//  SGVideoConfiguration.h
//  SGMediaKit
//
//  Created by Single on 28/11/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import "SGPLFGraphicMacro.h"

typedef NS_ENUM(NSUInteger, SGVideoQuality) {
    SGVideoQualityLow,
    SGVideoQualityMedium,
    SGVideoQualityHigh,
    SGVideoQualityUltra,
};

typedef NS_ENUM(NSUInteger, SGVideoSize) {
    SGVideoSize640X480,
    SGVideoSize960x540,
    SGVideoSize1280x720,
    SGVideoSize1920x1080,
};

@interface SGVideoConfiguration : NSObject

+ (instancetype)defaultVideoConfiguration;
+ (instancetype)defaultVideoConfigurationWithQuality:(SGVideoQuality)videoQuality;

@property (nonatomic, assign, readonly) SGVideoSize size;
@property (nonatomic, assign, readonly) NSUInteger frameRate;
@property (nonatomic, assign, readonly) NSUInteger bitRate;

#if SGPLATFORM_TARGET_OS_MAC
- (CGSize)pixelsSize;
#elif SGPLATFORM_TARGET_OS_IPHONE
- (CGSize)pixelsSize:(UIInterfaceOrientation)orientation;
#endif

- (NSString *)sessionPreset;

@end
