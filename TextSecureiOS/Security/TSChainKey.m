//
//  TSChainKey.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 02/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSChainKey.h"

@implementation TSChainKey

-(instancetype) initWithChainKeyWithKey:(NSData*)key index:(int)index{
    self = [super init];
    if (self) {
        _key = key;
        _index = index;
    }
    return self;
}

@end
