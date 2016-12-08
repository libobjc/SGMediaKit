//
//  SGAVPlayer.h
//  SGPlayer
//
//  Created by Single on 16/6/28.
//  Copyright © 2016年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "SGPlayer.h"
#import "SGAVView.h"

@interface SGAVPlayer : NSObject

+ (instancetype)playerWithURL:(NSURL *)contentURL;
+ (instancetype)playerWithURL:(NSURL *)contentURL videoType:(SGVideoType)videoType;

@property (nonatomic, weak) SGPlayer * abstractPlayer;
@property (nonatomic, copy, readonly) NSURL * contentURL;
@property (nonatomic, assign, readonly) SGVideoType videoType;
@property (nonatomic, assign) SGDisplayMode displayMode;
@property (nonatomic, strong, readonly) SGAVView * view;
@property (nonatomic, assign) BOOL viewAnimationHidden;     // default is NO;

@property (nonatomic, assign, readonly) SGPlayerState state;
@property (nonatomic, assign, readonly) NSTimeInterval progress;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) NSTimeInterval playableTime;
@property (nonatomic, assign) NSTimeInterval playableBufferInterval;    // default is 2s
@property (nonatomic, assign, readonly) BOOL seeking;
@property (nonatomic, assign) CGFloat volume;

- (void)replaceVideoWithURL:(NSURL *)contentURL;
- (void)replaceVideoWithURL:(NSURL *)contentURL videoType:(SGVideoType)videoType;

- (void)play;
- (void)pause;
- (void)stop;
- (void)seekToTime:(NSTimeInterval)time;
- (void)seekToTime:(NSTimeInterval)time completeHandler:(void(^)(BOOL finished))completeHandler;
- (UIImage *)snapshot;

- (void)setViewTapBlock:(void(^)())block;   // view tap action

@end
