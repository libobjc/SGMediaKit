//
//  SGGLFFView.m
//  SGMediaKit
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGGLFFView.h"
#import "SGGLFFProgram.h"

@interface SGGLFFView ()

@property (nonatomic, strong) SGGLProgram * program;

@end

@implementation SGGLFFView

- (void)setupProgram
{
    self.program = [SGGLFFProgram program];
    [self.program use];
    [self.program bindVariable];
}

- (void)setupSubClass
{
    
}

- (BOOL)updateTexture
{
    return YES;
}

@end
