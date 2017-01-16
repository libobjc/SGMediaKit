//
//  SGGLModel.h
//  SGMediaKit
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface SGGLModel : NSObject

@property (nonatomic, assign) int index_count;

+ (SGGLModel *)normalModel;
+ (SGGLModel *)vrModel;

- (void)bindPositionLocation:(GLint)position_location textureCoordLocation:(GLint)textureCoordLocation;

@end
