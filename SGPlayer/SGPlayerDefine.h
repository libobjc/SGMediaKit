//
//  SGPlayerDefine.h
//  SGPlayer
//
//  Created by Single on 16/8/15.
//  Copyright © 2016年 single. All rights reserved.
//

#ifndef SGPlayerDefine_h
#define SGPlayerDefine_h

#import <Foundation/Foundation.h>

// video type
typedef NS_ENUM(NSUInteger, SGVideoType) {
    SGVideoTypeNormal,  // normal
    SGVideoTypeVR,      // virtual reality
};

// player state
typedef NS_ENUM(NSUInteger, SGPlayerState) {
    SGPlayerStateNone = 0,          // none
    SGPlayerStateBuffering = 1,     // buffering
    SGPlayerStateReadyToPlay = 2,   // ready to play
    SGPlayerStatePlaying = 3,       // playing
    SGPlayerStateSuspend = 4,       // pause
    SGPlayerStateFinished = 5,      // finished
    SGPlayerStateFailed = 6,        // failed
};

// display mode
typedef NS_ENUM(NSUInteger, SGDisplayMode) {
    SGDisplayModeNormal,    // default
    SGDisplayModeBox,
};

// background mode
typedef NS_ENUM(NSUInteger, SGPlayerBackgroundMode) {
    SGPlayerBackgroundModeNothing,
    SGPlayerBackgroundModeAutoPlayAndPause,     // default
    SGPlayerBackgroundModeContinue,
};

// SGPlayer default identifier
FOUNDATION_EXPORT NSString * const SGPlayerDefaultIdentifier;

// notification name
FOUNDATION_EXPORT NSString * const SGPlayerErrorName;                   // player error
FOUNDATION_EXPORT NSString * const SGPlayerStateChangeName;     // player state change
FOUNDATION_EXPORT NSString * const SGPlayerProgressChangeName;  // player play progress change
FOUNDATION_EXPORT NSString * const SGPlayerPlayableChangeName;   // player playable progress change

// notification userinfo key
// all
FOUNDATION_EXPORT NSString * const SGPlayerIdentifierKey;
// error
FOUNDATION_EXPORT NSString * const SGPlayerErrorMessageKey;
FOUNDATION_EXPORT NSString * const SGPlayerErrorCodeKey;
// state
FOUNDATION_EXPORT NSString * const SGPlayerStatePreviousKey;
FOUNDATION_EXPORT NSString * const SGPlayerStateCurrentKey;
// progress
FOUNDATION_EXPORT NSString * const SGPlayerProgressPercentKey;
FOUNDATION_EXPORT NSString * const SGPlayerProgressCurrentKey;
FOUNDATION_EXPORT NSString * const SGPlayerProgressTotalKey;
// playable
FOUNDATION_EXPORT NSString * const SGPlayerPlayablePercentKey;
FOUNDATION_EXPORT NSString * const SGPlayerPlayableCurrentKey;
FOUNDATION_EXPORT NSString * const SGPlayerPlayableTotalKey;
FOUNDATION_EXPORT NSString * const SGPlayerPlayableTotalKey;

#endif
