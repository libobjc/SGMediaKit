//
//  SGAudioManager.m
//  SGMediaKit
//
//  Created by Single on 09/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGAudioManager.h"
#import "KxAudioManager.h"

@implementation SGAudioManager

+ (instancetype)manager
{
    return [KxAudioManager audioManager];
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

@end
