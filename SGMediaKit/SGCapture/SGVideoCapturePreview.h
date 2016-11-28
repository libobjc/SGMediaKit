//
//  SGVideoCaptureView.h
//  SGMediaKit
//
//  Created by Single on 23/11/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GPUImageView;

@interface SGVideoCapturePreview : UIView

@property (nonatomic, strong, readonly) GPUImageView * gpuImageView;

@end
