//
//  NSDictionary+SGFFmpeg.h
//  SGMediaKit
//
//  Created by Single on 04/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "avformat.h"

@interface NSDictionary (SGFFmpeg)

+ (instancetype)sg_dictionaryWithAVDictionary:(AVDictionary *)avDictionary;

@end
