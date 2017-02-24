//
//  SGGLAVTexture.h
//  SGMediaKit
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGPLFOpenGL.h"

@interface SGGLAVTexture : NSObject

@property (nonatomic, assign, readonly) BOOL hasTexture;

- (instancetype)initWithContext:(SGPLFGLContext *)context;
- (void)updateTextureWithPixelBuffer:(CVPixelBufferRef)pixelBuffer aspect:(CGFloat *)aspect needRelease:(BOOL)needRelease;

@end
