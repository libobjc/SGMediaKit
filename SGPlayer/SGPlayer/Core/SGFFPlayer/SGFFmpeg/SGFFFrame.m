//
//  SGFFFrame.m
//  SGMediaKit
//
//  Created by Single on 06/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFFrame.h"
#import "SGFFTools.h"

@implementation SGFFFrame

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
