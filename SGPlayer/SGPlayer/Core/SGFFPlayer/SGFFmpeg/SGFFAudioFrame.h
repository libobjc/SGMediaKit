//
//  SGFFAudioFrame.h
//  SGMediaKit
//
//  Created by Single on 2017/2/17.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGFFFrame.h"

@class SGFFAudioFrame;

@protocol SGFFAudioFrameDelegate <NSObject>

- (void)audioFrameDidStartPlaying:(SGFFAudioFrame *)audioFrame;
- (void)audioFrameDidStopPlaying:(SGFFAudioFrame *)audioFrame;
- (void)audioFrameDidCancel:(SGFFAudioFrame *)audioFrame;

@end

@interface SGFFAudioFrame : SGFFFrame

+ (instancetype)audioFrame;

@property (nonatomic, weak) id <SGFFAudioFrameDelegate> delegate;
@property (nonatomic, strong) NSData * samples;

- (void)startPlaying;
- (void)stopPlaying;
- (void)cancel;

@end
