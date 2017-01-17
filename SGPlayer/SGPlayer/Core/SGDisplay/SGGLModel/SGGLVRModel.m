//
//  SGGLVRModel.m
//  SGMediaKit
//
//  Created by Single on 17/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGGLVRModel.h"

@interface SGGLVRModel ()

{
    GLushort * _index_buffer;
    GLfloat * _vertex_buffer;
    GLfloat * _texture_buffer;
}

@end

@implementation SGGLVRModel

- (void)setupModel
{
    int slices_count = 200;
    int parallels_count = slices_count / 2;
    float step = (2.0f * M_PI) / (float)slices_count;
    float radius = 1.0f;
    
    self.index_count = slices_count * parallels_count * 6;
    _index_buffer = malloc(sizeof(GLushort) * self.index_count);
    self.vertex_count = (slices_count + 1) * (parallels_count + 1);
    _vertex_buffer = malloc(sizeof(GLfloat) * 3 * self.vertex_count);
    _texture_buffer = malloc(sizeof(GLfloat) * 2 * self.vertex_count);
    
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

- (void)setupBuffer
{
    // index
    GLuint index_id;
    glGenBuffers(1, &index_id);
    self.index_id = index_id;
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.index_id);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, self.index_count * sizeof(GLushort), _index_buffer, GL_STATIC_DRAW);
    
    // vertex
    GLuint vertex_id;
    glGenBuffers(1, &vertex_id);
    self.vertex_id = vertex_id;
    glBindBuffer(GL_ARRAY_BUFFER, self.vertex_id);
    glBufferData(GL_ARRAY_BUFFER, self.vertex_count * 3 * sizeof(GLfloat), _vertex_buffer, GL_STATIC_DRAW);
    
    // texture coord
    GLuint texture_id;
    glGenBuffers(1, &texture_id);
    self.texture_id = texture_id;
    glBindBuffer(GL_ARRAY_BUFFER, self.texture_id);
    glBufferData(GL_ARRAY_BUFFER, self.vertex_count * 2 * sizeof(GLfloat), _texture_buffer, GL_DYNAMIC_DRAW);
    
    [self freeBuffer];
}

- (void)freeBuffer
{
    free(_index_buffer);
    free(_vertex_buffer);
    free(_texture_buffer);
    
    _index_buffer = NULL;
    _vertex_buffer = NULL;
    _texture_buffer = NULL;
}

@end
