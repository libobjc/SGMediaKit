//
//  SGGLModel.m
//  SGMediaKit
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGGLModel.h"
#import "SGPlayerMacro.h"

@implementation SGGLModel

+ (instancetype)model
{
    return [[self alloc] init];
}

- (void)bindPositionLocation:(GLint)position_location textureCoordLocation:(GLint)textureCoordLocation
{
    // index
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.index_id);
    
    // vertex
    glBindBuffer(GL_ARRAY_BUFFER, self.vertex_id);
    glEnableVertexAttribArray(position_location);
    glVertexAttribPointer(position_location, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), NULL);
    
    // texture coord
    glBindBuffer(GL_ARRAY_BUFFER, self.texture_id);
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
    [self setupBuffer];
}

- (void)clear
{
    glDeleteBuffers(1, &_index_id);
    glDeleteBuffers(1, &_index_id);
    glDeleteBuffers(1, &_texture_id);
    self.index_id = 0;
    self.vertex_id = 0;
    self.texture_id = 0;
}

- (void)dealloc
{
    [self clear];
    SGPlayerLog(@"%@ release", self.class);
}

#pragma mark - subclass override

- (void)setupModel {}
- (void)setupBuffer {}

@end
