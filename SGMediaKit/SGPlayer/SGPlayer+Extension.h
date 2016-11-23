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

#pragma mark - SGPlayer Extsion Category

@interface SGPlayer (Extension)

+ (void)registerPlayerNotificationTarget:(id)target stateAction:(SEL)stateAction progressAction:(SEL)progressAction playableAction:(SEL)playableAction;      // object's class is NSNotification
- (void)registerPlayerNotificationTarget:(id)target stateAction:(SEL)stateAction progressAction:(SEL)progressAction playableAction:(SEL)playableAction;      // object's class is NSNotification
+ (void)removePlayerNotificationTarget:(id)target;
- (void)removePlayerNotificationTarget:(id)target;

@end

#pragma mark - Models

@interface SGModel : NSObject
@property (nonatomic, copy) NSString * identifier;
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

@interface SGError : SGModel
@property (nonatomic, copy) NSString * message;
@property (nonatomic, assign) NSInteger code;
+ (SGError *)errorFromUserInfo:(NSDictionary *)userInfo;
@end

