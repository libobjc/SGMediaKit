//
//  SGGLView.h
//  SGMediaKit
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "SGPlayerDefine.h"
#import "SGGLProgram.h"
#import "SGDisplayView.h"

@interface SGGLView : GLKView

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

+ (instancetype)viewWithDisplayView:(SGDisplayView *)displayView;

@property (nonatomic, weak, readonly) SGDisplayView * displayView;

#pragma mark - subclass override

- (SGGLProgram *)program;

- (void)setupProgram;
- (void)setupSubClass;
- (BOOL)updateTexture;

@end
