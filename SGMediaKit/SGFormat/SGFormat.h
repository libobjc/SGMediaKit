//
//  SGFormat.h
//  SGMediaKit
//
//  Created by Single on 06/12/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SGFormat;

@protocol SGFormatDelegate <NSObject>

- (void)formatDidStart:(SGFormat *)format;
- (void)format:(SGFormat *)format didChangeProgross:(float)progress;
- (void)format:(SGFormat *)format didCompleteWithError:(NSError *)error;

@end

@interface SGFormat : NSObject

+ (instancetype)formatWithSourceFileURL:(NSURL *)sourceFileURL;
- (instancetype)initWithSourceFileURL:(NSURL *)sourceFileURL;

@property (nonatomic, weak) id <SGFormatDelegate> delegate;

@property (nonatomic, copy, readonly) NSURL * sourceFileURL;
@property (nonatomic, copy) NSURL * destinationFileURL;
@property (nonatomic, copy) NSString * qualityType;
@property (nonatomic, copy) NSString * fileType;

@property (nonatomic, assign, readonly) float progress;

- (void)start;

@end
