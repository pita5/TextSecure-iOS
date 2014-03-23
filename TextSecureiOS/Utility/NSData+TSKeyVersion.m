//
//  NSData+TSKeyVersion.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 17/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "NSData+TSKeyVersion.h"

@implementation NSData (TSKeyVersion)

- (NSData*)prependVersionByte{
    NSMutableData *concatenatedData = [NSMutableData data];
    uint intVal = 0x05;
    Byte *byteData = (Byte*)malloc(1);
    byteData[0] = intVal;
    [concatenatedData appendBytes:byteData length:1];
    [concatenatedData appendData:self];
    return [concatenatedData copy];
}

-(NSData *)removeVersionByte{
#warning THIS IS CRASHING ON FIRST RECEIVE CRASHY CRASH CRASH
    return [self subdataWithRange:NSMakeRange(1, 32)]; // THIS IS CRASHING
}

@end
