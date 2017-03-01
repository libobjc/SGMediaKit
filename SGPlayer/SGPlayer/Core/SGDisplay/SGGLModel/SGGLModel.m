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
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, self.index_count * sizeof(GLushort), self.index_data, GL_STATIC_DRAW);
    
    // vertex
    glBindBuffer(GL_ARRAY_BUFFER, self.vertex_id);
    glBufferData(GL_ARRAY_BUFFER, self.vertex_count * 3 * sizeof(GLfloat), self.vertex_data, GL_STATIC_DRAW);
    glEnableVertexAttribArray(position_location);
    glVertexAttribPointer(position_location, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), NULL);
    
    // texture coord
    glBindBuffer(GL_ARRAY_BUFFER, self.texture_id);
    glBufferData(GL_ARRAY_BUFFER, self.vertex_count * 2 * sizeof(GLfloat), self.texture_data, GL_DYNAMIC_DRAW);
    glEnableVertexAttribArray(textureCoordLocation);
    glVertexAttribPointer(textureCoordLocation, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*2, NULL);
}

- (instancetype)init
{
    if (self = [super init]) {
        [self setupModel];
    }
    return self;
}

- (void)dealloc
{
    SGPlayerLog(@"%@ release", self.class);
}

#pragma mark - subclass override

- (void)setupModel {}

@end
