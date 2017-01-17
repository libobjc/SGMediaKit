//
//  SGGLView.m
//  SGMediaKit
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGGLView.h"
#import "SGPlayer.h"
#import "SGGLNormalModel.h"
#import "SGGLVRModel.h"
#import "SGMatrix.h"
#import "SGDistortionRenderer.h"

@interface SGGLView () <GLKViewDelegate>

@property (nonatomic, weak) SGDisplayView * displayView;

@property (nonatomic, strong) SGGLNormalModel * normalModel;
@property (nonatomic, strong) SGGLVRModel * vrModel;
@property (nonatomic, strong) SGMatrix * matrix;
@property (nonatomic, strong) SGDistortionRenderer * distorionRenderer;

@end

@implementation SGGLView

+ (instancetype)viewWithDisplayView:(SGDisplayView *)displayView
{
    return [[self alloc] initWithDisplayView:displayView];
}

- (instancetype)initWithDisplayView:(SGDisplayView *)displayView
{
    if (self = [super initWithFrame:CGRectZero]) {
        self.displayView = displayView;
        [self setup];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.distorionRenderer.viewportSize = [self pixelSize];
}

- (CGSize)pixelSize
{
    NSInteger scale = [UIScreen mainScreen].scale;
    CGSize size = CGSizeMake(CGRectGetWidth(self.bounds) * scale, CGRectGetHeight(self.bounds) * scale);
    return size;
}

#pragma mark - setup

- (void)setup
{
    [self setupGLKView];
    [self setupProgram];
    [self setupModel];
    [self setupSubClass];
}

- (void)setupGLKView
{
    self.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    self.contentScaleFactor = [UIScreen mainScreen].scale;
    self.delegate = self;
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
}

- (void)setupModel
{
    self.normalModel = [SGGLNormalModel model];
    self.vrModel = [SGGLVRModel model];
}

- (void)setupProgram {};
- (void)setupSubClass {}
- (BOOL)updateTexture {return NO;}
- (SGGLProgram *)program {return nil;}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [self render];
}

- (void)render
{
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    SGVideoType videoType = self.displayView.abstractPlayer.videoType;
    SGDisplayMode displayMode = self.displayView.abstractPlayer.displayMode;
    
    if (videoType == SGVideoTypeVR && displayMode == SGDisplayModeBox) {
        [self.distorionRenderer beforDrawFrame];
    }

    BOOL success = [self updateTexture];
    if (!success) return;
    
    [self.program use];
    [self.program bindVariable];
    
    NSInteger scale = [UIScreen mainScreen].scale;
    CGRect rect = self.bounds;
    
    switch (videoType) {
        case SGVideoTypeNormal:
        {
            [self.normalModel bindPositionLocation:self.program.position_location textureCoordLocation:self.program.texture_coord_location];
            glViewport(0, 0, CGRectGetWidth(rect) * scale, CGRectGetHeight(rect) * scale);
            [self.program updateMatrix:GLKMatrix4Identity];
            glDrawElements(GL_TRIANGLES, self.normalModel.index_count, GL_UNSIGNED_SHORT, 0);
        }
            break;
        case SGVideoTypeVR:
        {
            [self.vrModel bindPositionLocation:self.program.position_location textureCoordLocation:self.program.texture_coord_location];
            switch (self.displayView.abstractPlayer.displayMode) {
                case SGDisplayModeNormal:
                {
                    GLKMatrix4 matrix;
                    BOOL success = [self.matrix singleMatrixWithSize:self.bounds.size matrix:&matrix];
                    if (success) {
                        glViewport(0, 0, CGRectGetWidth(rect) * scale, CGRectGetHeight(rect) * scale);
                        [self.program updateMatrix:matrix];
                        glDrawElements(GL_TRIANGLES, self.vrModel.index_count, GL_UNSIGNED_SHORT, 0);
                    }
                }
                    break;
                case SGDisplayModeBox:
                {
                    GLKMatrix4 leftMatrix;
                    GLKMatrix4 rightMatrix;
                    BOOL success = [self.matrix doubleMatrixWithSize:self.bounds.size leftMatrix:&leftMatrix rightMatrix:&rightMatrix];
                    if (success) {
                        glViewport(0, 0, CGRectGetWidth(rect)/2 * scale, CGRectGetHeight(rect) * scale);
                        [self.program updateMatrix:leftMatrix];
                        glDrawElements(GL_TRIANGLES, self.vrModel.index_count, GL_UNSIGNED_SHORT, 0);
                        
                        glViewport(CGRectGetWidth(rect)/2 * scale, 0, CGRectGetWidth(rect)/2 * scale, CGRectGetHeight(rect) * scale);
                        [self.program updateMatrix:rightMatrix];
                        glDrawElements(GL_TRIANGLES, self.vrModel.index_count, GL_UNSIGNED_SHORT, 0);
                    }
                }
                    break;
            }
        }
            break;
    }
    
    if (videoType == SGVideoTypeVR && displayMode == SGDisplayModeBox) {
        [self bindDrawable];
        [self.distorionRenderer afterDrawFrame];
    }
}

- (SGMatrix *)matrix
{
    if (!_matrix) {
        _matrix = [[SGMatrix alloc] init];
    }
    return _matrix;
}

- (SGDistortionRenderer *)distorionRenderer
{
    if (!_distorionRenderer) {
        _distorionRenderer = [SGDistortionRenderer distortionRenderer];
    }
    return _distorionRenderer;
}

@end
