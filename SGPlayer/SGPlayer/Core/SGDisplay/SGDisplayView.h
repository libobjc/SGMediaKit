//
//  SGDisplayView.h
//  SGMediaKit
//
//  Created by Single on 12/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "SGPlayerDefine.h"
#import "SGFFFrame.h"
#import "SGFingerRotation.h"

@class SGPlayer;
@class SGAVPlayer;
@class SGDisplayView;

typedef NS_ENUM(NSUInteger, SGDisplayRendererType) {
    SGDisplayRendererTypeEmpty,
    SGDisplayRendererTypeAVPlayerLayer,
    SGDisplayRendererTypeAVPlayerPixelBufferVR,
    SGDisplayRendererTypeFFmpegPexelBuffer,
    SGDisplayRendererTypeFFmpegPexelBufferVR,
};

@interface SGDisplayView : UIView

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

+ (instancetype)displayViewWithAbstractPlayer:(SGPlayer *)abstractPlayer;

@property (nonatomic, weak, readonly) SGPlayer * abstractPlayer;

@property (nonatomic, weak) SGAVPlayer * sgavplayer;
@property (nonatomic, assign) SGDisplayRendererType rendererType;
@property (nonatomic, strong) SGFingerRotation * fingerRotation;

//- (void)pause;
//- (void)resume;
- (void)cleanEmptyBuffer;
- (void)renderFrame:(SGFFVideoFrame *)displayFrame;

- (UIImage *)snapshot;

@end
