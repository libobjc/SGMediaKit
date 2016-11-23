//
//  SGAVGLMatrix.h
//  SGPlayer
//
//  Created by Single on 16/7/26.
//  Copyright © 2016年 single. All rights reserved.
//

#import <GLKit/GLKit.h>
#define default_degrees 60.0

@interface SGAVGLMatrix : NSObject

@property (assign, nonatomic) CGFloat fingerRotationX;
@property (assign, nonatomic) CGFloat fingerRotationY;

- (BOOL)singleMatrixWithSize:(CGSize)size matrix:(GLKMatrix4 *)matrix;
- (BOOL)doubleMatrixWithSize:(CGSize)size leftMatrix:(GLKMatrix4 *)leftMatrix rightMatrix:(GLKMatrix4 *)rightMatrix;

@end
