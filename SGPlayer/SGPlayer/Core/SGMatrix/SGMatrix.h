//
//  SGMatrix.h
//  SGMediaKit
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "SGFingerRotation.h"

@interface SGMatrix : NSObject

- (BOOL)singleMatrixWithSize:(CGSize)size matrix:(GLKMatrix4 *)matrix fingerRotation:(SGFingerRotation *)fingerRotation;
- (BOOL)doubleMatrixWithSize:(CGSize)size leftMatrix:(GLKMatrix4 *)leftMatrix rightMatrix:(GLKMatrix4 *)rightMatrix;

@end
