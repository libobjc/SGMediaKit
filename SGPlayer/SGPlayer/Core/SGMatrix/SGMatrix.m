//
//  SGMatrix.m
//  SGMediaKit
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGMatrix.h"
#import "SGPlayerMacro.h"
#import "SGSensors.h"
#import <CoreMotion/CoreMotion.h>

@interface SGMatrix ()

@property (nonatomic, strong) SGSensors * sensors;

@end

@implementation SGMatrix

- (instancetype)init
{
    if (self = [super init]) {
        
        [self setupSensors];
    }
    return self;
}

#pragma mark - sensors

- (void)setupSensors
{
    self.sensors = [[SGSensors alloc] init];
    [self.sensors start];
}

- (BOOL)singleMatrixWithSize:(CGSize)size matrix:(GLKMatrix4 *)matrix
{
    if (!self.sensors.isReady) return NO;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, -self.fingerRotationX);
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, self.sensors.modelView);
    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, self.fingerRotationY);
    
    float aspect = fabs(size.width / size.height);
    GLKMatrix4 mvpMatrix = GLKMatrix4Identity;
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(default_degrees), aspect, 0.1f, 400.0f);
    GLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(0, 0, 0.0, 0, 0, -1000, 0, 1, 0);
    mvpMatrix = GLKMatrix4Multiply(projectionMatrix, viewMatrix);
    mvpMatrix = GLKMatrix4Multiply(mvpMatrix, modelViewMatrix);
    
    * matrix = mvpMatrix;
    
    return YES;
}

- (BOOL)doubleMatrixWithSize:(CGSize)size leftMatrix:(GLKMatrix4 *)leftMatrix rightMatrix:(GLKMatrix4 *)rightMatrix
{
    if (!self.sensors.isReady) return NO;
    
    GLKMatrix4 modelViewMatrix = self.sensors.modelView;
    
    float aspect = fabs(size.width / 2 / size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(default_degrees), aspect, 0.1f, 400.0f);
    
    CGFloat distance = 0.012;
    
    GLKMatrix4 leftViewMatrix = GLKMatrix4MakeLookAt(-distance, 0, 0.0, 0, 0, -1000, 0, 1, 0);
    GLKMatrix4 rightViewMatrix = GLKMatrix4MakeLookAt(distance, 0, 0.0, 0, 0, -1000, 0, 1, 0);
    
    GLKMatrix4 leftMvpMatrix = GLKMatrix4Multiply(projectionMatrix, leftViewMatrix);
    GLKMatrix4 rightMvpMatrix = GLKMatrix4Multiply(projectionMatrix, rightViewMatrix);
    
    leftMvpMatrix = GLKMatrix4Multiply(leftMvpMatrix, modelViewMatrix);
    rightMvpMatrix = GLKMatrix4Multiply(rightMvpMatrix, modelViewMatrix);
    
    * leftMatrix = leftMvpMatrix;
    * rightMatrix = rightMvpMatrix;
    
    return YES;
}

- (void)dealloc
{
    SGPlayerLog(@"SGAVGLMatrix release");
    [self.sensors stop];
}

@end
