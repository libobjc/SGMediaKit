//
//  SGVideoConfiguration.h
//  SGMediaKit
//
//  Created by Single on 28/11/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SGVideoQuality) {
    SGVideoQualityLow,
    SGVideoQualityMedium,
    SGVideoQualityHigh,
};

typedef NS_ENUM(NSUInteger, SGVideoSize) {
    SGVideoSize540p,
    SGVideoSize720p,
    SGVideoSize1080p,
};

@interface SGVideoConfiguration : NSObject

+ (instancetype)defaultVideoConfiguration;
+ (instancetype)defaultVideoConfigurationWithQuality:(SGVideoQuality)videoQuality;

@property (nonatomic, assign) SGVideoSize size;
@property (nonatomic, assign) NSUInteger frameRate;
@property (nonatomic, assign) NSUInteger bitRate;

- (CGSize)pixelsSize:(UIInterfaceOrientation)orientation;
- (NSString *)sessionPreset;

@end
