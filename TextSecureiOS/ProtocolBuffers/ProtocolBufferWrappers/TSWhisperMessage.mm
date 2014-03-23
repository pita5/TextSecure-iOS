//
//  TSWhisperMessage.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/7/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSWhisperMessage.hh"

@implementation TSWhisperMessage

-(id) initWithTextSecureProtocolData:(NSData*) data {
    throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"'abstract method' must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}
-(NSData*) getTextSecureProtocolData {
    throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"'abstract method' must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}





@end
