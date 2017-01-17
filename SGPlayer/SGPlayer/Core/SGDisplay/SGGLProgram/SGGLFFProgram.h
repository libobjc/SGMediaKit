//
//  SGGLFFProgram.h
//  SGMediaKit
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGGLProgram.h"

@interface SGGLFFProgram : SGGLProgram

+ (instancetype)program;

@property (nonatomic, assign) GLint sampler_location;

@end
