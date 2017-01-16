//
//  SGFFFrame.h
//  SGMediaKit
//
//  Created by Single on 06/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>

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

@property (nonatomic, strong) NSData * luma;
@property (nonatomic, strong) NSData * chromaB;
@property (nonatomic, strong) NSData * chromaR;

@property (nonatomic, assign) NSUInteger width;
@property (nonatomic, assign) NSUInteger height;
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
