//
//  SGGLModel.m
//  SGMediaKit
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGGLModel.h"
#import "SGPlayerMacro.h"

#define ES_PI  (3.14159265f)

@interface SGGLModel ()

{
    GLuint _index_id;
    GLushort * _index_buffer;
    
    GLuint _vertex_id;
    int _vertex_count;
    GLfloat * _vertex_buffer;
    
    GLuint _texture_id;
    GLfloat * _texture_buffer;
}

@end

@implementation SGGLModel

+ (SGGLModel *)normalModel
{
    return [[self alloc] init];
}

+ (SGGLModel *)vrModel
{
    return [[self alloc] init];
}

- (void)bindPositionLocation:(GLint)position_location textureCoordLocation:(GLint)textureCoordLocation
{
    // index
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _index_id);
    
    // vertex
    glBindBuffer(GL_ARRAY_BUFFER, _vertex_id);
    glEnableVertexAttribArray(position_location);
    glVertexAttribPointer(position_location, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), NULL);
    
    // texture coord
    glBindBuffer(GL_ARRAY_BUFFER, _texture_id);
    glEnableVertexAttribArray(textureCoordLocation);
    glVertexAttribPointer(textureCoordLocation, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*2, NULL);
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
    [self setupModel];
    [self setupBufferData];
}

- (void)setupBufferData
{
    // index
    glGenBuffers(1, &_index_id);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _index_id);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, _index_count * sizeof(GLushort), _index_buffer, GL_STATIC_DRAW);
    
    // vertex
    glGenBuffers(1, &_vertex_id);
    glBindBuffer(GL_ARRAY_BUFFER, _vertex_id);
    glBufferData(GL_ARRAY_BUFFER, _vertex_count * 3 * sizeof(GLfloat), _vertex_buffer, GL_STATIC_DRAW);
    
    // texture coord
    glGenBuffers(1, &_texture_id);
    glBindBuffer(GL_ARRAY_BUFFER, _texture_id);
    glBufferData(GL_ARRAY_BUFFER, _vertex_count * 2 * sizeof(GLfloat), _texture_buffer, GL_DYNAMIC_DRAW);
}

- (void)setupModel
{
    int slices_count = 200;
    int parallels_count = slices_count / 2;
    float step = (2.0f * ES_PI) / (float)slices_count;
    float radius = 1.0f;
    
    _index_count = slices_count * parallels_count * 6;
    _index_buffer = malloc(sizeof(GLushort) * _index_count);
    _vertex_count = (slices_count + 1) * (parallels_count + 1);
    _vertex_buffer = malloc(sizeof(GLfloat) * 3 * _vertex_count);
    _texture_buffer = malloc(sizeof(GLfloat) * 2 * _vertex_count);
    
    int runCount = 0;
    for (int i = 0; i < parallels_count + 1; i++)
    {
        for (int j = 0; j < slices_count + 1; j++)
        {
            int vertex = (i * (slices_count + 1) + j) * 3;
            
            if (_vertex_buffer)
            {
                _vertex_buffer[vertex + 0] = radius * sinf(step * (float)i) * cosf(step * (float)j);
                _vertex_buffer[vertex + 1] = radius * cosf(step * (float)i);
                _vertex_buffer[vertex + 2] = radius * sinf(step * (float)i) * sinf(step * (float)j);
            }
            
            if (_texture_buffer)
            {
                int textureIndex = (i * (slices_count + 1) + j) * 2;
                _texture_buffer[textureIndex + 0] = (float)j / (float)slices_count;
                _texture_buffer[textureIndex + 1] = ((float)i / (float)parallels_count);
            }
            
            if (_index_buffer && i < parallels_count && j < slices_count)
            {
                _index_buffer[runCount++] = i * (slices_count + 1) + j;
                _index_buffer[runCount++] = (i + 1) * (slices_count + 1) + j;
                _index_buffer[runCount++] = (i + 1) * (slices_count + 1) + (j + 1);
                
                _index_buffer[runCount++] = i * (slices_count + 1) + j;
                _index_buffer[runCount++] = (i + 1) * (slices_count + 1) + (j + 1);
                _index_buffer[runCount++] = i * (slices_count + 1) + (j + 1);
            }
        }
    }
}

- (void)clear
{
    glDeleteBuffers(1, &_index_id);
    glDeleteBuffers(1, &_vertex_id);
    glDeleteBuffers(1, &_texture_id);
    _index_id = 0;
    _vertex_id = 0;
    _texture_id = 0;
}

- (void)dealloc
{
    [self clear];
    SGPlayerLog(@"SGAVGLModel release");
}

@end
