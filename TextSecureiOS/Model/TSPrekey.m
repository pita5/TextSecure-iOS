//
//  TSPrekey.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 05/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSPrekey.h"

@implementation TSPrekey

static NSString* const kCoderIdentityKey               = @"kCoderIdentityKey";
static NSString* const kCoderEphemeral                 = @"kCoderEphemeral";
static NSString* const kCoderPrekeyId                  = @"kCoderPrekeyId";
- (instancetype)initWithIdentityKey:(NSData*)identityKey ephemeral:(NSData*)ephemeral prekeyId:(int)prekeyId{
    self = [super init];
    
    if(self){
        _identityKey  = identityKey;
        _ephemeralKey = ephemeral;
        _prekeyId     = prekeyId;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [self initWithIdentityKey:[aDecoder decodeObjectForKey:kCoderIdentityKey] ephemeral:[aDecoder decodeObjectForKey:kCoderEphemeral] prekeyId:[aDecoder decodeIntegerForKey:kCoderPrekeyId]];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.identityKey forKey:kCoderIdentityKey];
    [aCoder encodeObject:self.ephemeralKey forKey:kCoderEphemeral];
    [aCoder encodeInteger:self.prekeyId forKey:kCoderPrekeyId];
}

@end
