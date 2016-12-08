//
//  SGNotification.m
//  SGPlayer
//
//  Created by Single on 16/8/15.
//  Copyright © 2016年 single. All rights reserved.
//

#import "SGNotification.h"

@implementation SGNotification

+ (void)postPlayer:(SGPlayer *)player errorMessage:(NSString *)message code:(NSInteger)code
{
    if (!player) return;
    NSString * identifier = player.identifier;
    if (![identifier isKindOfClass:[NSString class]] || identifier == nil) identifier = SGPlayerDefaultIdentifier;
    if (![message isKindOfClass:[NSString class]] || message == nil) message = @"SGPlayer unknown error";
    if (code <= 0) code = 1900;
    NSDictionary * userInfo = @{
                                SGPlayerIdentifierKey : identifier,
                                SGPlayerErrorMessageKey : message,
                                SGPlayerErrorCodeKey : @(code)
                                };
    [self postNotificationName:SGPlayerErrorName object:player userInfo:userInfo];
}

+ (void)postPlayer:(SGPlayer *)player statePrevious:(SGPlayerState)previous current:(SGPlayerState)current
{
    if (!player) return;
    NSString * identifier = player.identifier;
    if (![identifier isKindOfClass:[NSString class]] || identifier == nil) identifier = SGPlayerDefaultIdentifier;
    NSDictionary * userInfo = @{
                                SGPlayerIdentifierKey : identifier,
                                SGPlayerStatePreviousKey : @(previous),
                                SGPlayerStateCurrentKey : @(current)
                                };
    [self postNotificationName:SGPlayerStateChangeName object:player userInfo:userInfo];
}

+ (void)postPlayer:(SGPlayer *)player progressPercent:(NSNumber *)percent current:(NSNumber *)current total:(NSNumber *)total
{
    if (!player) return;
    NSString * identifier = player.identifier;
    if (![identifier isKindOfClass:[NSString class]] || identifier == nil) identifier = SGPlayerDefaultIdentifier;
    if (![percent isKindOfClass:[NSNumber class]]) percent = @(0);
    if (![current isKindOfClass:[NSNumber class]]) current = @(0);
    if (![total isKindOfClass:[NSNumber class]]) total = @(0);
    NSDictionary * userInfo = @{
                                SGPlayerIdentifierKey : identifier,
                                SGPlayerProgressPercentKey : percent,
                                SGPlayerProgressCurrentKey : current,
                                SGPlayerProgressTotalKey : total
                                };
    [self postNotificationName:SGPlayerProgressChangeName object:player userInfo:userInfo];
}

+ (void)postPlayer:(SGPlayer *)player playablePercent:(NSNumber *)percent current:(NSNumber *)current total:(NSNumber *)total
{
    if (!player) return;
    NSString * identifier = player.identifier;
    if (![identifier isKindOfClass:[NSString class]] || identifier == nil) identifier = SGPlayerDefaultIdentifier;
    if (![percent isKindOfClass:[NSNumber class]]) percent = @(0);
    if (![current isKindOfClass:[NSNumber class]]) current = @(0);
    if (![total isKindOfClass:[NSNumber class]]) total = @(0);
    NSDictionary * userInfo = @{
                                SGPlayerIdentifierKey : identifier,
                                SGPlayerPlayablePercentKey : percent,
                                SGPlayerPlayableCurrentKey : current,
                                SGPlayerPlayableTotalKey : total,
                                };
    [self postNotificationName:SGPlayerPlayableChangeName object:player userInfo:userInfo];
}

+ (void)postNotificationName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo
{
    if ([NSThread isMainThread]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:object userInfo:userInfo];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:name object:object userInfo:userInfo];
        });
    }
}

@end
