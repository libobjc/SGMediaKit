//
//  SGFormatFactory.h
//  SGMediaKit
//
//  Created by Single on 06/12/2016.
//  Copyright © 2016 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGFormatFactory : NSObject

+ (instancetype)formatFactory;

@property (nonatomic, assign, readonly) BOOL running;

- (void)mpeg4FormatWithSourceFileURL:(NSURL *)sourceFileURL
                  destinationFileURL:(NSURL *)destinationFileURL
                     progressHandler:(void(^)(float progress))progressHandler
                   completionHandler:(void(^)(NSError * error))completionHandler;

@end
