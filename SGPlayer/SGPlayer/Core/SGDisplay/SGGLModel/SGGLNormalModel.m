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

static GLuint vertex_buffer_id = 0;
static GLuint index_buffer_id = 0;
static GLuint texture_buffer_id = 0;

static int const index_count = 6;
static int const vertex_count = 4;

@implementation SGGLNormalModel

void setup_normal()
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        glGenBuffers(1, &index_buffer_id);
        glGenBuffers(1, &vertex_buffer_id);
        glGenBuffers(1, &texture_buffer_id);
    });
}

- (void)setupModel
{
    setup_normal();
    self.index_count = index_count;
    self.vertex_count = vertex_count;
    self.index_id = index_buffer_id;
    self.vertex_id = vertex_buffer_id;
    self.texture_id = texture_buffer_id;
    self.index_data = index_buffer_data;
    self.vertex_data = vertex_buffer_data;
    self.texture_data = texture_buffer_data;
}

@end
