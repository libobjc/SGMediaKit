//
//  SGAVGLView.m
//  SGPlayer
//
//  Created by Single on 16/7/25.
//  Copyright © 2016年 Hanton. All rights reserved.
//

#import "SGAVGLView.h"
#import "SGPlayerMacro.h"
#import "SGAVGLProgram.h"
#import "SGAVGLModel.h"
#import "SGAVGLMatrix.h"
#import "SGAVGLTexture.h"
#import "SGDistortionRenderer.h"

@interface SGAVGLView () <GLKViewDelegate>

{
    dispatch_once_t setupOnceToken;
}

@property (nonatomic, strong) CADisplayLink * displayLink;

@property (nonatomic, strong) SGAVGLProgram * program;
@property (nonatomic, strong) SGAVGLModel * model;
@property (nonatomic, strong) SGAVGLMatrix * matrix;
@property (nonatomic, strong) SGAVGLTexture * texture;
@property (nonatomic, strong) SGDistortionRenderer * distorionRenderer;

@end

@implementation SGAVGLView

#pragma mark - 初始化

- (void)layoutSubviews
{
    [super layoutSubviews];
    dispatch_once(&setupOnceToken, ^{
        [self setup];
    });
    self.distorionRenderer.viewportSize = [self pixelSize];
}

- (CGSize)pixelSize
{
    NSInteger scale = [UIScreen mainScreen].scale;
    CGSize size = CGSizeMake(CGRectGetWidth(self.bounds) * scale, CGRectGetHeight(self.bounds) * scale);
    return size;
}

#pragma mark - Setup

- (void)setup
{
    [self setupGL];
    [self setupDisplayLink];
    [self setupGesture];
}

#pragma mark - Setup OpenGL

// 设置OpenGL
- (void)setupGL
{
    [self setupGLKView];
    [self setupGLProgram];
    [self setupGLModel];
}

// GLKView
- (void)setupGLKView
{
    self.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    self.contentScaleFactor = [UIScreen mainScreen].scale;
    self.delegate = self;
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
}

// Program
- (void)setupGLProgram
{
    self.program = [SGAVGLProgram program];
    [self.program use];
    [self.program prepareVariable];
}

// buffers
- (void)setupGLModel
{
    self.model = [SGAVGLModel model];
    [self.model bindBufferVertexPointer:self.program.pPosition textureCoordPointer:self.program.pTextureCoord];
}

#pragma mark - Setup Other

- (void)setupGesture
{
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
    [self addGestureRecognizer:tap];
}

- (void)tapGestureAction:(UITapGestureRecognizer *)tap
{
    SGPlayerLog(@"SGAVGLView tap action");
    if ([self.sgDelegate respondsToSelector:@selector(sgav_glViewTapAction:)]) {
        [self.sgDelegate sgav_glViewTapAction:self];
    }
}

- (void)setupDisplayLink
{
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkAction)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.displayLink.paused = NO;
}

#pragma mark - OpenGL draw

- (void)displayLinkAction
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        [self display];
    }
}

// draw GLKView
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    CVPixelBufferRef pixelBuffer = [self.dataSource sgav_glViewPixelBufferToDraw:self];
    if (!pixelBuffer && !self.texture.hasTexture) return;
    
    if (self.displayMode == SGDisplayModeBox) {
        [self.distorionRenderer beforDraw];
    }
    
    [self.program use];
    
    [self.texture updateTextureWithPixelBuffer:pixelBuffer];
    [self.program prepareVariable];
    [self.model bindBufferVertexPointer:self.program.pPosition textureCoordPointer:self.program.pTextureCoord];
    
    NSInteger scale = [UIScreen mainScreen].scale;
    switch (self.displayMode) {
        case SGDisplayModeNormal:
        {
            GLKMatrix4 matrix;
            BOOL success = [self.matrix singleMatrixWithSize:self.bounds.size matrix:&matrix];
            if (success) {
                glViewport(0, 0, CGRectGetWidth(rect) * scale, CGRectGetHeight(rect) * scale);
                glUniformMatrix4fv(self.program.pMvpMatrix, 1, GL_FALSE, matrix.m);
                glDrawElements(GL_TRIANGLES, self.model.indexCount, GL_UNSIGNED_SHORT, 0);
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
                glUniformMatrix4fv(self.program.pMvpMatrix, 1, GL_FALSE, leftMatrix.m);
                glDrawElements(GL_TRIANGLES, self.model.indexCount, GL_UNSIGNED_SHORT, 0);
                
                glViewport(CGRectGetWidth(rect)/2 * scale, 0, CGRectGetWidth(rect)/2 * scale, CGRectGetHeight(rect) * scale);
                glUniformMatrix4fv(self.program.pMvpMatrix, 1, GL_FALSE, rightMatrix.m);
                glDrawElements(GL_TRIANGLES, self.model.indexCount, GL_UNSIGNED_SHORT, 0);
            }
        }
            break;
    }
    
    if (self.displayMode == SGDisplayModeBox) {
        [self bindDrawable];
        [self.distorionRenderer afterDraw];
    }
}

#pragma mark - 手势响应

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.displayMode == SGDisplayModeBox) return;
    
    UITouch * touch = [touches anyObject];
    float distanceX = [touch locationInView:touch.view].x - [touch previousLocationInView:touch.view].x;
    float distanceY = [touch locationInView:touch.view].y - [touch previousLocationInView:touch.view].y;
    distanceX *= 0.005;
    distanceY *= 0.005;
    self.matrix.fingerRotationX += distanceY *  default_degrees / 100;
    self.matrix.fingerRotationY -= distanceX *  default_degrees / 100;
}

#pragma mark - Setter/Getter

- (void)setPaused:(BOOL)paused
{
    self.displayLink.paused = paused;
}

- (BOOL)paused
{
    return self.displayLink.paused;
}

- (SGAVGLMatrix *)matrix
{
    if (!_matrix) {
        _matrix = [[SGAVGLMatrix alloc] init];
    }
    return _matrix;
}

- (SGAVGLTexture *)texture
{
    if (!_texture) {
        _texture = [[SGAVGLTexture alloc] initWithContext:self.context];
    }
    return _texture;
}

- (SGDistortionRenderer *)distorionRenderer
{
    if (!_distorionRenderer) {
        _distorionRenderer = [SGDistortionRenderer distortionRenderer];
    }
    return _distorionRenderer;
}

#pragma mark - release

- (void)dealloc
{
    SGPlayerLog(@"SGAVGLView release");
    [self clearGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)removeFromSuperview
{
    [self invalidate];
    [super removeFromSuperview];
}

- (void)invalidate
{
    [self.displayLink invalidate];
}

- (void)clearGL
{
    [EAGLContext setCurrentContext:self.context];
    self.program = nil;
}

@end
