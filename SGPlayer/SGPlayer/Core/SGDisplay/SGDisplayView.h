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
#import "SGDisplayFrame.h"

typedef NS_ENUM(NSUInteger, SGDisplayRendererType) {
    SGDisplayRendererTypeAVPlayerLayer,
    SGDisplayRendererTypeAVPlayerPixelBufferVR,
    SGDisplayRendererTypeFFmpegPexelBuffer,
    SGDisplayRendererTypeFFmpegPexelBufferVR,
};

@interface SGDisplayView : UIView

@property (nonatomic, weak) AVPlayer * avplayer;
@property (nonatomic, assign) SGDisplayRendererType rendererType;

- (void)renderFrame:(SGDisplayFrame *)displayFrame;
- (void)clean;

@end
