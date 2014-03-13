//
//  TSChain.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 11/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSReceivingChain.h"

NSString *const kChainKey       = @"kChainKey";
NSString *const kChainEphemeral = @"kChainEphemeral";
NSString *const kChainMessages  = @"kChainMessages";

@implementation TSReceivingChain


-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    
    if (self) {
        _messageKeys = [aDecoder decodeObjectForKey:kChainMessages];
        _ephemeral   = [aDecoder decodeObjectForKey:kChainEphemeral];
        _chainKey    = [aDecoder decodeObjectForKey:kChainKey];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.chainKey forKey:kChainKey];
    [aCoder encodeObject:self.messageKeys forKey:kChainMessages];
    [aCoder encodeObject:self.ephemeral forKey:kChainEphemeral];
}

- (instancetype)initWithChainKey:(TSChainKey *)chainKey ephemeral:(NSData *)ephemeral{
    self = [super init];
    
    if (self) {
        _chainKey = chainKey;
        _ephemeral = ephemeral;
    }
    return self;
}

@end
