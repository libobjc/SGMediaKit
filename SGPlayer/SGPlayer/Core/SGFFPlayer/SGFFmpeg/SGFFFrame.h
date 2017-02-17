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
    SGFFFrameTypeAVYUVVideo,
    SGFFFrameTypeCVYUVVideo,
    SGFFFrameTypeAudio,
    SGFFFrameTypeSubtitle,
    SGFFFrameTypeArtwork,
};


@interface SGFFFrame : NSObject

@property (nonatomic, assign) SGFFFrameType type;
@property (nonatomic, assign) NSTimeInterval position;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign, readonly) int size;

@end


@interface SGFFSubtileFrame : SGFFFrame

@end


@interface SGFFArtworkFrame : SGFFFrame

@property (nonatomic, strong) NSData * picture;

@end
