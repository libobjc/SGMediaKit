//
//  SGGLNormalModel.m
//  SGMediaKit
//
//  Created by Single on 17/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGGLNormalModel.h"

static GLKVector3 vertex_buffer_data[] = {
    {-1, 1, 0.0},
    {1, 1, 0.0},
    {1, -1, 0.0},
    {-1, -1, 0.0},
};

static GLushort index_buffer_data[] = {
    0, 1, 2, 0, 2, 3
};

static GLKVector2 texture_buffer_data[] = {
    {0.0, 0.0},
    {1.0, 0.0},
    {1.0, 1.0},
    {0.0, 1.0},
};

@implementation SGGLNormalModel

- (void)setupModel
{
    self.index_count = 6;
    self.vertex_count = 4;
}

- (void)setupBuffer
{
    // index
    GLuint index_id;
    glGenBuffers(1, &index_id);
    self.index_id = index_id;
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.index_id);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, self.index_count * sizeof(GLushort), index_buffer_data, GL_STATIC_DRAW);
    
    // vertex
    GLuint vertex_id;
    glGenBuffers(1, &vertex_id);
    self.vertex_id = vertex_id;
    glBindBuffer(GL_ARRAY_BUFFER, self.vertex_id);
    glBufferData(GL_ARRAY_BUFFER, self.vertex_count * 3 * sizeof(GLfloat), vertex_buffer_data, GL_STATIC_DRAW);
    
    // texture coord
    GLuint texture_id;
    glGenBuffers(1, &texture_id);
    self.texture_id = texture_id;
    glBindBuffer(GL_ARRAY_BUFFER, self.texture_id);
    glBufferData(GL_ARRAY_BUFFER, self.vertex_count * 2 * sizeof(GLfloat), texture_buffer_data, GL_DYNAMIC_DRAW);
}

@end
