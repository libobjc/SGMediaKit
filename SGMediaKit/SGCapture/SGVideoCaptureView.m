//
//  SGVideoCaptureView.m
//  SGMediaKit
//
//  Created by Single on 23/11/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import "SGVideoCaptureView.h"
#import <GPUImage/GPUImageFramework.h>

@interface SGVideoCaptureView ()

@property (nonatomic, strong) GPUImageView * gpuImageView;

@end

@implementation SGVideoCaptureView

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self UILayout];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self UILayout];
    }
    return self;
}

- (void)UILayout
{
    [self addSubview:self.gpuImageView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.gpuImageView.frame = self.bounds;
}

- (GPUImageView *)gpuImageView
{
    if(!_gpuImageView) {
        _gpuImageView = [[GPUImageView alloc] initWithFrame:self.bounds];
        [_gpuImageView setFillMode:kGPUImageFillModePreserveAspectRatioAndFill];
    }
    return _gpuImageView;
}

@end
