//
//  SGFormatMPEG4.h
//  SGMediaKit
//
//  Created by Single on 06/12/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SGFormatQuality) {
    SGFormatQualityLow,
    SGFormatQualityMedium,
    SGFormatQualityHighest,
};

@interface SGFormatMPEG4 : NSObject

+ (void)formatWithSourceFileURL:(NSURL *)sourceFileURL destinationFileURL:(NSURL *)destinationFileURL quality:(SGFormatQuality)quality progressHandler:(void(^)(float progress))progressHandler completionHandler:(void(^)(NSError * error))completionHandler;

@end
