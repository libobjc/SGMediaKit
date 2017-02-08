//
//  SGAudioManager.m
//  SGMediaKit
//
//  Created by Single on 09/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGAudioManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface SGAudioManager ()

@property (nonatomic, assign) BOOL registered;
@property (nonatomic, strong) AVAudioSession * audioSession;

@end

@implementation SGAudioManager

+ (instancetype)manager
{
    static SGAudioManager * manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    if (self = [super init]) {
        
    }
    return self;
}

- (void)registerAudioSession
{
    if (!self.registered) {
        self.audioSession = [AVAudioSession sharedInstance];
        NSError * error;
        BOOL success = [self.audioSession setActive:YES error:&error];
        if (!success || error) {
            NSLog(@"AVAudioSession active error : %@", error);
            return;
        }
        self.registered = YES;
    }
}

- (void)unregisterAudioSession
{
    if (self.registered) {
        
        self.registered = NO;
    }
}

- (void)play
{
    
}

- (void)pause
{
    
}

- (Float64)samplingRate
{
    return (Float64)self.audioSession.sampleRate;
}

- (UInt32)channelCount
{
    return (UInt32)self.audioSession.outputNumberOfChannels;
}

- (void)dealloc
{
    [self unregisterAudioSession];
}

@end
