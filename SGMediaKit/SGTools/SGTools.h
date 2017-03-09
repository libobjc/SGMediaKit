//
//  SGTools.h
//  SGMediaKit
//
//  Created by Single on 2017/3/9.
//  Copyright © 2017年 single. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
#define SGMediaKitLog(...) NSLog(__VA_ARGS__)
#else
#define SGMediaKitLog(...)
#endif
