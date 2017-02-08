//
//  SGAudioManager.h
//  SGMediaKit
//
//  Created by Single on 09/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGAudioManager : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)manager;

@property (nonatomic, assign, readonly) Float64 samplingRate;
@property (nonatomic, assign, readonly) UInt32 channelCount;

- (void)play;
- (void)pause;

- (void)registerAudioSession;
- (void)unregisterAudioSession;

@end
