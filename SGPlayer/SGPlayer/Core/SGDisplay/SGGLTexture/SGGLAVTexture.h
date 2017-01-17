//
//  SGGLAVTexture.h
//  SGMediaKit
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface SGGLAVTexture : NSObject

@property (nonatomic, assign, readonly) BOOL hasTexture;

- (instancetype)initWithContext:(EAGLContext *)context;
- (void)updateTextureWithPixelBuffer:(CVPixelBufferRef)pixelBuffer aspect:(CGFloat *)aspect;

@end
