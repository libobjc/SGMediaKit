//
//  SGAVGLTexture.h
//  SGPlayer
//
//  Created by Single on 16/7/26.
//  Copyright © 2016年 single. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface SGAVGLTexture : NSObject

@property (nonatomic, assign, readonly) BOOL hasTexture;

- (instancetype)initWithContext:(EAGLContext *)context;
- (void)updateTextureWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
