//
//  TSSendingChain.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 13/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSSendingChain.h"

@implementation TSSendingChain

static NSString* const kChainKey       = @"kChainKey";
static NSString* const kChainEphemeral = @"kChainEphemeral";

- (instancetype)initWithChainKey:(TSChainKey*)chainKey ephemeral:(TSECKeyPair*)ephemeral{
    self = [super init];
    
    if (self) {
        _chainKey = chainKey;
        _ephemeral = ephemeral;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    
    if (self) {
        _chainKey  = [aDecoder decodeObjectForKey:kChainKey];
        _ephemeral = [aDecoder decodeObjectForKey:kChainEphemeral];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.chainKey forKey:kChainKey];
    [aCoder encodeObject:self.ephemeral forKey:kChainEphemeral];
}


@end
