//
//  SGFFFormatContext.h
//  SGMediaKit
//
//  Created by Single on 2017/2/17.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "avformat.h"

@class SGFFFormatContext;

@protocol SGFFFormatContextDelegate <NSObject>

- (BOOL)formatContextNeedInterrupt:(SGFFFormatContext *)formatContext;

@end

@interface SGFFFormatContext : NSObject

{
@public
    AVFormatContext * _format_context;
    AVCodecContext * _video_codec_context;
    AVCodecContext * _audio_codec_context;
}

+ (instancetype)formatContextWithContentURL:(NSURL *)contentURL delegate:(id <SGFFFormatContextDelegate>)delegate;

@property (nonatomic, weak) id <SGFFFormatContextDelegate> delegate;

@property (nonatomic, copy, readonly) NSError * error;

@property (nonatomic, copy, readonly) NSDictionary * metadata;
@property (nonatomic, assign, readonly) NSTimeInterval bitrate;
@property (nonatomic, assign, readonly) NSTimeInterval duration;

@property (nonatomic, assign, readonly) BOOL videoEnable;
@property (nonatomic, assign, readonly) BOOL audioEnable;

@property (nonatomic, assign, readonly) int videoStreamIndex;
@property (nonatomic, assign, readonly) int audioStreamIndex;

@property (nonatomic, copy, readonly) NSArray <NSNumber *> * videoStreamIndexs;
@property (nonatomic, copy, readonly) NSArray <NSNumber *> * audioStreamIndexs;

@property (nonatomic, assign, readonly) NSTimeInterval videoTimebase;
@property (nonatomic, assign, readonly) NSTimeInterval videoFPS;
@property (nonatomic, assign, readonly) CGSize videoPresentationSize;
@property (nonatomic, assign, readonly) CGFloat videoAspect;

@property (nonatomic, assign, readonly) NSTimeInterval audioTimebase;

- (void)setupSync;
- (void)destroy;

- (void)seekFile:(NSTimeInterval)time;
- (int)readFrame:(AVPacket *)packet;

@end
