//
//  SGFFTrack.h
//  SGMediaKit
//
//  Created by Single on 2017/3/6.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFMetadata.h"

@interface SGFFTrack : NSObject

@property (nonatomic, assign) int index;

@property (nonatomic, strong) SGFFMetadata * metadata;

@end
