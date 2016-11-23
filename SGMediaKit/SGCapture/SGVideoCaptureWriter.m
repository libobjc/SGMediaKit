//
//  SGVideoCaptureWriter.m
//  SGMediaKit
//
//  Created by Single on 23/11/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import "SGVideoCaptureWriter.h"

@implementation SGVideoCaptureWriter

+ (GPUImageMovieWriter *)defaultWriterWithURL:(NSURL *)URL size:(CGSize)size
{
    GPUImageMovieWriter * movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:URL size:size];
    movieWriter.encodingLiveVideo = YES;
    movieWriter.shouldPassthroughAudio = YES;
    return movieWriter;
}

@end
