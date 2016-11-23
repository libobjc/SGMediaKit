//
//  SGVideoRecord.h
//  SGMediaKit
//
//  Created by Single on 23/11/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SGVideoRecord : NSObject

@property (nonatomic, strong, readonly) UIView * view;

- (void)startRecording;
- (void)finishRecordingWithCompletionHandler:(void (^)(NSURL * videoURL))handler;

@end
