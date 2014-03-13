//
//  RKCK.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/15/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "RKCK.h"
#import "TSECKeyPair.h"
#import "TSHKDF.h"
#import "TSMessagesDatabase.h"

@implementation MKCK

+(instancetype) initWithData:(NSData*)data {
    
    MKCK* mkck = [[MKCK alloc] init];
    
    mkck.MK =  [data subdataWithRange:NSMakeRange(0, 32)];
    mkck.CK = [data subdataWithRange:NSMakeRange(32, 32)];
    
    return mkck;
}

@end

@implementation RKCK

+(instancetype) initWithRK:(NSData*)rootKey CK:(TSChainKey *)chainKey{
    RKCK *rkck = [[RKCK alloc]init];
    rkck.RK = rootKey;
    rkck.CK = chainKey;
    return rkck;
}

+(instancetype) initWithData:(NSData*)data {
    RKCK *rkck = [[RKCK alloc] init];
    rkck.RK =  [data subdataWithRange:NSMakeRange(0, 32)];
    rkck.CK = [[TSChainKey alloc]initWithChainKeyWithKey:[data subdataWithRange:NSMakeRange(32, 32)] index:0];
    return rkck;
}

- (RKCK*)createChainWithEphemeral:(TSECKeyPair*)myEphemeral fromTheirProvideEphemeral:(NSData*)theirPublicEphemeral{
    NSData *inputKeyMaterial = [myEphemeral generateSharedSecretFromPublicKey:theirPublicEphemeral];
    return [[self class] initWithData:[TSHKDF deriveKeyFromMaterial:inputKeyMaterial outputLength:64 info:[@"WhisperRatchet" dataUsingEncoding:NSUTF8StringEncoding] salt:self.RK]];
}

@end
