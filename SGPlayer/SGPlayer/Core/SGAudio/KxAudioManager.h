//
//  KxAudioManager.h
//  kxmovie
//
//  Created by Kolyvan on 23.10.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/kxmovie
//  this file is part of KxMovie
//  KxMovie is licenced under the LGPL v3, see lgpl-3.0.txt


#import <CoreFoundation/CoreFoundation.h>

@class KxAudioManager;

@protocol KxAudioManagerDelegate <NSObject>
- (void)audioManager:(KxAudioManager *)audioManager outputData:(float *)data numberOfFrames:(UInt32)numFrames numberOfChannels:(UInt32)numChannels;
@end

@interface KxAudioManager : NSObject

+ (instancetype)audioManager;

@property (nonatomic, assign, readonly) UInt32 numOutputChannels;
@property (nonatomic, assign, readonly) Float64 samplingRate;
@property (nonatomic, assign, readonly) UInt32 numBytesPerSample;
@property (nonatomic, assign, readonly) Float32 outputVolume;
@property (nonatomic, assign, readonly) BOOL playing;
@property (nonatomic, copy, readonly) NSString * audioRoute;

@property (nonatomic, weak) id <KxAudioManagerDelegate> delegate;

- (BOOL)activateAudioSession;
- (void)deactivateAudioSession;
- (BOOL)play;
- (void)pause;

@end
