//
//  SGAudioManager.h
//  SGMediaKit
//
//  Created by Single on 09/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SGAudioManager;

@protocol SGAudioManagerDelegate <NSObject>
- (void)audioManager:(SGAudioManager *)audioManager outputData:(float *)outputData numberOfFrames:(UInt32)numFrames numberOfChannels:(UInt32)numChannels;
@end

@interface SGAudioManager : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)manager;

@property (nonatomic, weak) id <SGAudioManagerDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL playing;

@property (nonatomic, assign, readonly) Float64 samplingRate;
@property (nonatomic, assign, readonly) UInt32 channelCount;

- (void)play;
- (void)pause;

- (BOOL)registerAudioSession;
- (void)unregisterAudioSession;

@end
