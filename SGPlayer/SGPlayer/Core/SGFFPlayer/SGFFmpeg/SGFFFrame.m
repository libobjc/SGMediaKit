//
//  SGFFFrame.m
//  SGMediaKit
//
//  Created by Single on 06/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFFrame.h"

@implementation SGFFFrame

@end

@implementation SGFFVideoFrame

- (SGFFFrameType)type
{
    return SGFFFrameTypeVideo;
}

- (void)dealloc
{
    if (self.luma.bytes) {
        free(self.luma.bytes);
    }
    if (self.chromaB.bytes) {
        free(self.chromaB.bytes);
    }
    if (self.chromaR.bytes) {
        free(self.chromaR.bytes);
    }
    NSLog(@"SGFFVideoFrame release");
}

@end

@implementation SGFFAudioFrame

- (SGFFFrameType)type
{
    return SGFFFrameTypeAudio;
}

@end

@implementation SGFFSubtileFrame

- (SGFFFrameType)type
{
    return SGFFFrameTypeSubtitle;
}

@end

@implementation SGFFArtworkFrame

- (SGFFFrameType)type
{
    return SGFFFrameTypeArtwork;
}

@end
