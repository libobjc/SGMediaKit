//
//  SGPlayerDecoder.h
//  SGMediaKit
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPlayerDefine.h"

@interface SGPlayerDecoder : NSObject

+ (instancetype)defaultDecoder;
- (SGVideoFormat)formatForContentURL:(NSURL *)contentURL;
- (SGDecoderType)decoderTypeForContentURL:(NSURL *)contentURL;

@property (nonatomic, assign) SGDecoderType unkonwnFormat;   // default is SGDecodeTypeFFmpeg
@property (nonatomic, assign) SGDecoderType mpeg4Format;     // default is SGDecodeTypeAVPlayer
@property (nonatomic, assign) SGDecoderType flvFormat;       // default is SGDecodeTypeFFmpeg
@property (nonatomic, assign) SGDecoderType m3u8Format;      // default is SGDecodeTypeAVPlayer
@property (nonatomic, assign) SGDecoderType rtmpFormat;      // default is SGDecodeTypeFFmpeg
@property (nonatomic, assign) SGDecoderType rtspFormat;      // default is SGDecodeTypeFFmpeg

@end
