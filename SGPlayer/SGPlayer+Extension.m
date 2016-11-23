//
//  SGPlayer+Extsion.m
//  SGPlayer
//
//  Created by Single on 16/8/16.
//  Copyright © 2016年 single. All rights reserved.
//

#import "SGPlayer+Extension.h"

@implementation SGPlayer (Extension)

+ (void)registerPlayerNotificationTarget:(id)target stateAction:(SEL)stateAction progressAction:(SEL)progressAction playableAction:(SEL)playableAction
{
    [self registerPlayerNotification:nil target:target stateAction:stateAction progressAction:progressAction playableAction:playableAction errorAction:nil];
}

- (void)registerPlayerNotificationTarget:(id)target stateAction:(SEL)stateAction progressAction:(SEL)progressAction playableAction:(SEL)playableAction
{
    [self.class registerPlayerNotification:self target:target stateAction:stateAction progressAction:progressAction playableAction:playableAction errorAction:nil];
}

+ (void)registerPlayerNotification:(SGPlayer *)player target:(id)target stateAction:(SEL)stateAction progressAction:(SEL)progressAction playableAction:(SEL)playableAction errorAction:(SEL)errorAction
{
    if (!target) return;
    [self removePlayerNotification:player target:target];
    if (stateAction) [[NSNotificationCenter defaultCenter] addObserver:target selector:stateAction name:SGPlayerStateChangeName object:player];
    if (progressAction) [[NSNotificationCenter defaultCenter] addObserver:target selector:progressAction name:SGPlayerProgressChangeName object:player];
    if (playableAction) [[NSNotificationCenter defaultCenter] addObserver:target selector:playableAction name:SGPlayerPlayableChangeName object:player];
    if (errorAction) [[NSNotificationCenter defaultCenter] addObserver:target selector:errorAction name:SGPlayerErrorName object:player];
}

- (void)removePlayerNotificationTarget:(id)target
{
    [self.class removePlayerNotification:self target:target];
}

+ (void)removePlayerNotificationTarget:(id)target
{
    [self removePlayerNotification:nil target:target];
}

+ (void)removePlayerNotification:(SGPlayer *)player target:(id)target
{
    [[NSNotificationCenter defaultCenter] removeObserver:target name:SGPlayerStateChangeName object:player];
    [[NSNotificationCenter defaultCenter] removeObserver:target name:SGPlayerProgressChangeName object:player];
    [[NSNotificationCenter defaultCenter] removeObserver:target name:SGPlayerPlayableChangeName object:player];
    [[NSNotificationCenter defaultCenter] removeObserver:target name:SGPlayerErrorName object:player];
}

@end

@implementation SGModel

@end

@implementation SGState

+ (SGState *)stateFromUserInfo:(NSDictionary *)userInfo
{
    SGState * state = [[SGState alloc] init];
    state.identifier = [userInfo objectForKey:SGPlayerIdentifierKey];
    state.previous = [[userInfo objectForKey:SGPlayerStatePreviousKey] integerValue];
    state.current = [[userInfo objectForKey:SGPlayerStateCurrentKey] integerValue];
    return state;
}

@end

@implementation SGProgress

+ (SGProgress *)progressFromUserInfo:(NSDictionary *)userInfo
{
    SGProgress * progress = [[SGProgress alloc] init];
    progress.identifier = [userInfo objectForKey:SGPlayerIdentifierKey];
    progress.percent = [[userInfo objectForKey:SGPlayerProgressPercentKey] doubleValue];
    progress.current = [[userInfo objectForKey:SGPlayerProgressCurrentKey] doubleValue];
    progress.total = [[userInfo objectForKey:SGPlayerProgressTotalKey] doubleValue];
    return progress;
}

@end

@implementation SGPlayable

+ (SGPlayable *)playableFromUserInfo:(NSDictionary *)userInfo
{
    SGPlayable * playable = [[SGPlayable alloc] init];
    playable.identifier = [userInfo objectForKey:SGPlayerIdentifierKey];
    playable.percent = [[userInfo objectForKey:SGPlayerPlayablePercentKey] doubleValue];
    playable.current = [[userInfo objectForKey:SGPlayerPlayableCurrentKey] doubleValue];
    playable.total = [[userInfo objectForKey:SGPlayerPlayableTotalKey] doubleValue];
    return playable;
}

@end

@implementation SGError

+ (SGError *)errorFromUserInfo:(NSDictionary *)userInfo
{
    SGError * error = [[SGError alloc] init];
    error.identifier = [userInfo objectForKey:SGPlayerIdentifierKey];
    error.message = [userInfo objectForKey:SGPlayerErrorMessageKey];
    error.code = [[userInfo objectForKey:SGPlayerErrorCodeKey] integerValue];
    return error;
}

@end
