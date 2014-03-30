//
//  RKCK.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/15/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "RKCK.h"
#import "TSECKeyPair.h"
#import "TSDerivedSecrets.h"
#import "TSMessagesDatabase.h"

@implementation RKCK

+(instancetype) initWithRK:(NSData*)rootKey CK:(TSChainKey *)chainKey{
    RKCK *rkck = [[RKCK alloc]init];
    rkck.RK = rootKey;
    rkck.CK = chainKey;
    return rkck;
}

+(instancetype) initWithRootMasterKey:(NSData*)data{
    RKCK *rkck = [[RKCK alloc] init];
    TSDerivedSecrets *derivedSecrets = [TSDerivedSecrets derivedInitialSecretsWithMasterKey:data];
    rkck.RK =  derivedSecrets.cipherKey;
    rkck.CK = [[TSChainKey alloc]initWithChainKeyWithKey:derivedSecrets.macKey index:0];
    return rkck;
}

+(instancetype) initWithRootKey:(NSData*)rootKey sharedSecret:(NSData*)sharedSecret{
    RKCK *rkck = [[RKCK alloc] init];
    TSDerivedSecrets *derivedSecrets = [TSDerivedSecrets derivedRatchetedSecretsWithSharedSecret:sharedSecret rootKey:rootKey];
    rkck.RK =  derivedSecrets.cipherKey;
    rkck.CK = [[TSChainKey alloc]initWithChainKeyWithKey:derivedSecrets.macKey index:0];
    return rkck;
}

- (instancetype)createChainWithEphemeral:(TSECKeyPair*)myEphemeral fromTheirProvideEphemeral:(NSData*)theirPublicEphemeral{
    NSData *inputKeyMaterial = [myEphemeral generateSharedSecretFromPublicKey:theirPublicEphemeral];
    return [[self class]initWithRootKey:self.RK sharedSecret:inputKeyMaterial];
}

-(NSString*)debugDescription {
    return [NSString stringWithFormat:@"RK: %@\n",self.RK];
}

@end
