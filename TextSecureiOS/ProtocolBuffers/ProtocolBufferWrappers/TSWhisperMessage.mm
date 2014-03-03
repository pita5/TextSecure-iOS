//
//  TSWhisperMessage.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/7/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSWhisperMessage.hh"

@implementation TSWhisperMessage



-(NSData*) serializedTextSecureBuffer {
    NSMutableData *serialized = [NSMutableData data];
    [serialized appendData:self.version];
    [serialized appendData:[self serializedProtocolBuffer]];
    return serialized;
}


@end
