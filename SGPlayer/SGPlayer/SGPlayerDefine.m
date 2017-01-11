//
//  SGPlayerDefine.m
//  SGPlayer
//
//  Created by Single on 2016/11/9.
//  Copyright © 2016年 single. All rights reserved.
//

#ifndef SGPlayerDefine_m
#define SGPlayerDefine_m

#import <Foundation/Foundation.h>

// notification name
NSString * const SGPlayerErrorName = @"SGPlayerErrorName";                   // player error
NSString * const SGPlayerStateChangeName = @"SGPlayerStateChangeName";     // player state change
NSString * const SGPlayerProgressChangeName = @"SGPlayerProgressChangeName";  // player play progress change
NSString * const SGPlayerPlayableChangeName = @"SGPlayerPlayableChangeName";   // player playable progress change

// notification userinfo key
// all
NSString * const SGPlayerIdentifierKey = @"identifier";
// error
NSString * const SGPlayerErrorKey = @"error";
// state
NSString * const SGPlayerStatePreviousKey = @"previous";
NSString * const SGPlayerStateCurrentKey = @"current";
// progress
NSString * const SGPlayerProgressPercentKey = @"percent";
NSString * const SGPlayerProgressCurrentKey = @"current";
NSString * const SGPlayerProgressTotalKey = @"total";
// playable
NSString * const SGPlayerPlayablePercentKey = @"percent";
NSString * const SGPlayerPlayableCurrentKey = @"current";
NSString * const SGPlayerPlayableTotalKey = @"total";

#endif
