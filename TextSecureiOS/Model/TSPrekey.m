//
//  TSPrekey.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 05/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSPrekey.h"

@implementation TSPrekey

- (instancetype)initWithIdentityKey:(NSData*)identityKey ephemeral:(NSData*)ephemeral prekeyId:(int)prekeyId{
    self = [super init];
    
    if(self){
        _identityKey = identityKey;
        _ephemeralKey = ephemeral;
        _prekeyId = prekeyId;
    }
    
    return self;
}

@end
