//
//  NSDictionary+SGFFmpeg.m
//  SGMediaKit
//
//  Created by Single on 04/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "NSDictionary+SGFFmpeg.h"

@implementation NSDictionary (SGFFmpeg)

+ (instancetype)sg_dictionaryWithAVDictionary:(AVDictionary *)avDictionary
{
    if (avDictionary == NULL) return nil;
    
    int count = av_dict_count(avDictionary);
    if (count <= 0) return nil;
    
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
    
    AVDictionaryEntry * entry = NULL;
    while ((entry = av_dict_get(avDictionary, "", entry, AV_DICT_IGNORE_SUFFIX))) {
        @autoreleasepool {
            NSString * key = [NSString stringWithUTF8String:entry->key];
            NSString * value = [NSString stringWithUTF8String:entry->value];
            [dictionary setObject:value forKey:key];
        }
    }
    
    return dictionary;
}

@end
