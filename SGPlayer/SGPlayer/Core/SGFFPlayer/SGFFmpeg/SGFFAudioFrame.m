//
//  SGFFAudioFrame.m
//  SGMediaKit
//
//  Created by Single on 2017/2/17.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGFFAudioFrame.h"

@implementation SGFFAudioFrame

- (SGFFFrameType)type
{
    return SGFFFrameTypeAudio;
}

- (int)size
{
    return (int)self.samples.length;
}

@end
