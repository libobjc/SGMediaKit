//
//  SGGLFFView.m
//  SGMediaKit
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGGLFFView.h"

@interface SGGLFFView ()

@property (nonatomic, strong) SGGLProgram * program;

@end

@implementation SGGLFFView

- (void)setupProgram
{
    self.program = [SGGLProgram ffmpegProgram];
    [self.program prepare];
}

- (void)setupSubClass
{
    
}

- (BOOL)updateTexture
{
    return YES;
}

@end
