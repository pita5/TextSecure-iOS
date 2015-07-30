//
//  NSString+randomString.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 23/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "NSString+randomString.h"

@implementation NSString (randomString)

static NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

+ (NSString*)genRandStringLength:(int)len {
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    
    return randomString;
}

@end
