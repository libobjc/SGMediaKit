//
//  SGPlayer+Extsion.h
//  SGPlayer
//
//  Created by Single on 16/8/16.
//  Copyright © 2016年 single. All rights reserved.
//

#import "SGPlayer.h"

@class SGState;
@class SGProgress;
@class SGPlayable;
@class SGError;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - SGPlayer Extsion Category

@interface SGPlayer (Extension)

+ (void)registerPlayerNotificationTarget:(id)target
                             stateAction:(nullable SEL)stateAction
                          progressAction:(nullable SEL)progressAction
                          playableAction:(nullable SEL)playableAction;      // object's class is NSNotification
+ (void)registerPlayerNotification:(nullable SGPlayer *)player
                            target:(id)target
                       stateAction:(nullable SEL)stateAction
                    progressAction:(nullable SEL)progressAction
                    playableAction:(nullable SEL)playableAction
                       errorAction:(nullable SEL)errorAction;
- (void)registerPlayerNotificationTarget:(id)target
                             stateAction:(nullable SEL)stateAction
                          progressAction:(nullable SEL)progressAction
                          playableAction:(nullable SEL)playableAction;      // object's class is NSNotification
- (void)registerPlayerNotificationTarget:(id)target
                             stateAction:(nullable SEL)stateAction
                          progressAction:(nullable SEL)progressAction
                          playableAction:(nullable SEL)playableAction
                             errorAction:(nullable SEL)errorAction;
+ (void)removePlayerNotificationTarget:(id)target;
- (void)removePlayerNotificationTarget:(id)target;

@end

#pragma mark - Models

@interface SGModel : NSObject
@end

@interface SGState : SGModel
@property (nonatomic, assign) SGPlayerState previous;
@property (nonatomic, assign) SGPlayerState current;
+ (SGState *)stateFromUserInfo:(NSDictionary *)userInfo;
@end

@interface SGProgress : SGModel
@property (nonatomic, assign) CGFloat percent;
@property (nonatomic, assign) CGFloat current;
@property (nonatomic, assign) CGFloat total;
+ (SGProgress *)progressFromUserInfo:(NSDictionary *)userInfo;
@end

@interface SGPlayable : SGModel
@property (nonatomic, assign) CGFloat percent;
@property (nonatomic, assign) CGFloat current;
@property (nonatomic, assign) CGFloat total;
+ (SGPlayable *)playableFromUserInfo:(NSDictionary *)userInfo;
@end

@interface SGErrorEvent : SGModel
@property (nonatomic, copy, nullable) NSDate * date;
@property (nonatomic, copy, nullable) NSString * URI;
@property (nonatomic, copy, nullable) NSString * serverAddress;
@property (nonatomic, copy, nullable) NSString * playbackSessionID;
@property (nonatomic, assign) NSInteger errorStatusCode;
@property (nonatomic, copy) NSString * errorDomain;
@property (nonatomic, copy, nullable) NSString * errorComment;
@end

@interface SGError : SGModel
@property (nonatomic, copy) NSError * error;
@property (nonatomic, copy, nullable) NSData * extendedLogData;
@property (nonatomic, assign) NSStringEncoding extendedLogDataStringEncoding;
@property (nonatomic, copy, nullable) NSArray <SGErrorEvent *> * errorEvents;
+ (SGError *)errorFromUserInfo:(NSDictionary *)userInfo;
@end

NS_ASSUME_NONNULL_END
