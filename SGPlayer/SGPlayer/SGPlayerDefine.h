//
//  SGPlayerDefine.h
//  SGPlayer
//
//  Created by Single on 16/8/15.
//  Copyright © 2016年 single. All rights reserved.
//

#ifndef SGPlayerDefine_h
#define SGPlayerDefine_h

// extern
#if defined(__cplusplus)
#define SGPLAYER_EXTERN extern "C"
#else
#define SGPLAYER_EXTERN extern
#endif

#import <Foundation/Foundation.h>

// decode type
typedef NS_ENUM(NSUInteger, SGDecoderType) {
    SGDecoderTypeError,
    SGDecoderTypeAVPlayer,
    SGDecoderTypeFFmpeg,
};

// video format
typedef NS_ENUM(NSUInteger, SGVideoFormat) {
    SGVideoFormatError,
    SGVideoFormatUnknown,
    SGVideoFormatMPEG4,
    SGVideoFormatFLV,
    SGVideoFormatM3U8,
    SGVideoFormatRTMP,
};

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
SGPLAYER_EXTERN NSString * const SGPlayerDefaultIdentifier;

// notification name
SGPLAYER_EXTERN NSString * const SGPlayerErrorName;                   // player error
SGPLAYER_EXTERN NSString * const SGPlayerStateChangeName;     // player state change
SGPLAYER_EXTERN NSString * const SGPlayerProgressChangeName;  // player play progress change
SGPLAYER_EXTERN NSString * const SGPlayerPlayableChangeName;   // player playable progress change

// notification userinfo key
// all
SGPLAYER_EXTERN NSString * const SGPlayerIdentifierKey;
// error
SGPLAYER_EXTERN NSString * const SGPlayerErrorMessageKey;
SGPLAYER_EXTERN NSString * const SGPlayerErrorCodeKey;
// state
SGPLAYER_EXTERN NSString * const SGPlayerStatePreviousKey;
SGPLAYER_EXTERN NSString * const SGPlayerStateCurrentKey;
// progress
SGPLAYER_EXTERN NSString * const SGPlayerProgressPercentKey;
SGPLAYER_EXTERN NSString * const SGPlayerProgressCurrentKey;
SGPLAYER_EXTERN NSString * const SGPlayerProgressTotalKey;
// playable
SGPLAYER_EXTERN NSString * const SGPlayerPlayablePercentKey;
SGPLAYER_EXTERN NSString * const SGPlayerPlayableCurrentKey;
SGPLAYER_EXTERN NSString * const SGPlayerPlayableTotalKey;
SGPLAYER_EXTERN NSString * const SGPlayerPlayableTotalKey;

#endif
