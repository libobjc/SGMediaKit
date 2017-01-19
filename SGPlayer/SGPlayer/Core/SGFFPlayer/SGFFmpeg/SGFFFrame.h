//
//  SGFFFrame.h
//  SGMediaKit
//
//  Created by Single on 06/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "avformat.h"

typedef NS_ENUM(NSUInteger, SGFFFrameType) {
    SGFFFrameTypeVideo,
    SGFFFrameTypeAudio,
    SGFFFrameTypeSubtitle,
    SGFFFrameTypeArtwork,
};

@interface SGFFFrame : NSObject
@property (nonatomic, assign) SGFFFrameType type;
@property (nonatomic, assign) NSTimeInterval position;
@property (nonatomic, assign) NSTimeInterval duration;
@end

@interface SGFFVideoFrame : SGFFFrame

{
@public
    UInt8 * luma;
    UInt8 * chromaB;
    UInt8 * chromaR;
    
    int lumaLenght;
    int chromaBLenght;
    int chromaRLenght;
}

@property (nonatomic, assign, readonly) NSUInteger width;
@property (nonatomic, assign, readonly) NSUInteger height;

- (instancetype)initWithAVFrame:(AVFrame *)frame width:(int)width height:(int)height;

@end

@interface SGFFAudioFrame : SGFFFrame
@property (nonatomic, strong) NSData * samples;
@end

@interface SGFFSubtileFrame : SGFFFrame
@end

@interface SGFFArtworkFrame : SGFFFrame
@property (nonatomic, strong) NSData * picture;
//- (UIImage *)image;
@end
