//
//  SGGLAVProgram.m
//  SGMediaKit
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGGLAVProgram.h"
#import "SGAVGLShader.h"

@interface SGGLAVProgram ()

@end

@implementation SGGLAVProgram

+ (instancetype)program
{
    return [self programWithVertexShader:[NSString stringWithUTF8String:vertexShaderString]
                          fragmentShader:[NSString stringWithUTF8String:fragmentShaderString]];
}

- (void)bindVariable
{
    static GLfloat colorConversion709[] = {
        1.164,    1.164,     1.164,
        0.0,      -0.213,    2.112,
        1.793,    -0.533,    0.0,
    };
    glUniformMatrix3fv(self.colorConversionMatrix_location, 1, GL_FALSE, colorConversion709);
    
    glEnableVertexAttribArray(self.position_location);
    glEnableVertexAttribArray(self.texture_coord_location);
    
    glUniform1i(self.samplerY_location, 0);
    glUniform1i(self.samplerUV_location, 1);
}

- (void)setupVariable
{
    self.position_location = glGetAttribLocation(self.program_id, "position");
    self.texture_coord_location = glGetAttribLocation(self.program_id, "textureCoord");
    self.matrix_location = glGetUniformLocation(self.program_id, "mvpMatrix");
    self.samplerY_location = glGetUniformLocation(self.program_id, "SamplerY");
    self.samplerUV_location = glGetUniformLocation(self.program_id, "SamplerUV");
    self.colorConversionMatrix_location = glGetUniformLocation(self.program_id, "colorConversionMatrix");
}

@end
