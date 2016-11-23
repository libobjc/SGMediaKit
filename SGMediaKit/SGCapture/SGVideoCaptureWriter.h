//
//  SGVideoCaptureWriter.h
//  SGMediaKit
//
//  Created by Single on 23/11/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GPUImage/GPUImageFramework.h>

@interface SGVideoCaptureWriter : NSObject

+ (GPUImageMovieWriter *)defaultWriterWithURL:(NSURL *)URL size:(CGSize)size;

@end
