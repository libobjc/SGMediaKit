//
//  SGVideoCapture.h
//  SGMediaKit
//
//  Created by Single on 23/11/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GPUImage/GPUImageFramework.h>
#import "SGVideoCaptureView.h"

@class SGVideoCapture;

@protocol SGVideoCaptureDelegate <NSObject>

@optional;
- (void)videoCaptureWillStartRunning:(SGVideoCapture *)videoCapture;
- (void)videoCaptureDidStartRunning:(SGVideoCapture *)videoCapture;
- (void)videoCaptureWillStopRunning:(SGVideoCapture *)videoCapture;
- (void)videoCaptureDidStopRunning:(SGVideoCapture *)videoCapture;
- (GPUImageFilter *)filterInVideoCapture:(SGVideoCapture *)videoCapture;

@end

@interface SGVideoCapture : NSObject

@property (nonatomic, assign, readonly) BOOL running;
@property (nonatomic, strong, readonly) GPUImageVideoCamera * videoCamera;
@property (nonatomic, weak) id <SGVideoCaptureDelegate> delegate;
@property (nonatomic, strong, readonly) SGVideoCaptureView * view;

- (void)reloadFilter;

- (void)startRunning;
- (void)stopRunning;

@end
