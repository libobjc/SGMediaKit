//
//  SGAVGLProgram.m
//  SGPlayer
//
//  Created by Single on 16/7/25.
//  Copyright © 2016年 single. All rights reserved.
//

#import "SGAVGLProgram.h"
#import "SGPlayerMacro.h"
#import "SGAVGLShader.h"

@interface SGAVGLProgram ()

{
    GLuint _program_id;
    GLuint _vertexShader_id;
    GLuint _fragmentShader_id;
    
    GLuint _pSamplerY;
    GLuint _pSamplerUV;
    GLuint _pColorConversionMatrix;
}

@end

@implementation SGAVGLProgram

+ (instancetype)program
{
    return [[self alloc] init];
}

- (void)use
{
    glUseProgram(_program_id);
}

- (void)prepareVariable
{
    static GLfloat colorConversion709[] = {
        1.164,    1.164,     1.164,
        0.0,      -0.213,    2.112,
        1.793,    -0.533,    0.0,
    };
    glUniformMatrix3fv(_pColorConversionMatrix, 1, GL_FALSE, colorConversion709);
    
    glEnableVertexAttribArray(_pPosition);
    glEnableVertexAttribArray(_pTextureCoord);
    
    glUniform1i(_pSamplerY, 0);
    glUniform1i(_pSamplerUV, 1);
}

- (instancetype)init
{
    if (self = [super init]) {
        
        [self setup];
    }
    return self;
}

- (void)setup
{
    [self setupProgram];
    [self setupShader];
    [self linkProgram];
    [self setupVariable];
}

- (void)setupProgram
{
    _program_id = glCreateProgram();
}

- (void)setupShader
{
    // setup shader
    if (![self compileShader:&_vertexShader_id type:GL_VERTEX_SHADER string:vertexShaderString])
    {
        SGLog(@"load vertex shader failure");
    }
    if (![self compileShader:&_fragmentShader_id type:GL_FRAGMENT_SHADER string:fragmentShaderString])
    {
        SGLog(@"load fragment shader failure");
    }
    glAttachShader(_program_id, _vertexShader_id);
    glAttachShader(_program_id, _fragmentShader_id);
}

- (BOOL)linkProgram
{
    GLint status;
    glLinkProgram(_program_id);
    
    glGetProgramiv(_program_id, GL_LINK_STATUS, &status);
    if (status == GL_FALSE)
        return NO;
    
    [self clearShader];
    
    return YES;
}

- (void)setupVariable
{
    _pPosition = glGetAttribLocation(_program_id, "position");
    _pTextureCoord = glGetAttribLocation(_program_id, "textureCoord");
    _pMvpMatrix = glGetUniformLocation(_program_id, "mvpMatrix");
    _pSamplerY = glGetUniformLocation(_program_id, "SamplerY");
    _pSamplerUV = glGetUniformLocation(_program_id, "SamplerUV");
    _pColorConversionMatrix = glGetUniformLocation(_program_id, "colorConversionMatrix");
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type string:(const char *)shaderString
{
    if (!shaderString)
    {
        SGLog(@"Failed to load shader");
        return NO;
    }
    
    GLint status;
    
    * shader = glCreateShader(type);
    glShaderSource(* shader, 1, &shaderString, NULL);
    glCompileShader(* shader);
    glGetShaderiv(* shader, GL_COMPILE_STATUS, &status);
    if (status != GL_TRUE)
    {
        GLint logLength;
        glGetShaderiv(* shader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0) {
            GLchar * log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(* shader, logLength, &logLength, log);
            SGLog(@"Shader compile log:\n%s", log);
            free(log);
        }
    }
    
    return status == GL_TRUE;
}

- (void)clearShader
{
    if (_vertexShader_id) {
        glDeleteShader(_vertexShader_id);
    }
    
    if (_fragmentShader_id) {
        glDeleteShader(_fragmentShader_id);
    }
}

- (void)clearProgram
{
    if (_program_id) {
        glDeleteProgram(_program_id);
        _program_id = 0;
    }
}

- (void)dealloc
{
    SGLog(@"SGAVGLProgram release");
    
    [self clearShader];
    [self clearProgram];
}

@end
