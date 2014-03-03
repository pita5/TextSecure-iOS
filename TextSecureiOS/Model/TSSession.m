//
//  TSSession.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSUserKeysDatabase.h"
#import "TSSession.h"
#import "TSMessage.h"

@interface TSSession(){
    NSData *theirBaseKey;
   // TSECKeyPair *ourEphemeral;
    NSArray *receivingChains; // 5 last receiving chains
    NSArray *sendingChains; // 5 last sending chains
}
@end

@implementation TSSession

- (instancetype)initWithContact:(TSContact *)contact deviceId:(NSString *)deviceId{
  // Look up in database or create.

}


// Initialize Session with PreKey Message
- (instancetype)initWithContact:(TSContact *)contact deviceId:(int)deviceId preKeyWhisperMessage:(TSPreKeyWhisperMessage*)message{
    _contact = contact;
    _deviceId = deviceId?:1;
    _theirEphemeralKey = [message ephemeralKey];
    _theirIdentityKey = [message identityKey];
    theirBaseKey = [message baseKey];
    
    int preKeyId = [message.preKeyId intValue];
    if ([self processPrekey:preKeyId]) {
        // Process Message
    } else{
        // We just ignore it
    }
    
    return self;
}

- (NSData*)decrypt:(TSEncryptedWhisperMessage*)message{
    NSData *cipherText = message.message; // WHY NO CIPHERTEXT PROPERTY?
#warning Where is the cipherText?
    
    
}

- (NSData*)encrypt:(TSMessage*)message

#pragma mark PreKey utils

- (BOOL)processPrekey:(int)prekeyId {
    
    TSECKeyPair *preKeyPair = [TSUserKeysDatabase preKeyWithId:prekeyId];
    
    if (preKeyPair){
        
        // Clear previous records for this session
        [TSMessagesDatabase deleteSession:self];
    
        //3-way DHE
        RKCK *rootAndChainKey = [RKCK initWithData:[[self class] masterKeyBob:[self myIdentityKey] ourEphemeral:ourEphemeral theirIdentityPublicKey:self.theirIdentityKey theirEphemeralPublicKey:self.theirEphemeralKey]];
        
        // Generate new sending key
        TSECKeyPair *sendingKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
        
        [self setRootKey:rootAndChainKey.RK];
        [self setSenderChainWithKeyPair:sendingKey chainKey:[[TSChainKey alloc]initWithChainKeyWithKey:rootAndChainKey.CK index:0]];
        
        if (preKeyPair.preKeyId != kLastResortKeyId) {
            // Delete that preKey!
        }
        
    } else{
        // We probably have already processed that message.
#warning properly do error management
        @throw ([NSException exceptionWithName:@"" reason:@"" userInfo:@{}]);
        
    }
}

#pragma mark Chain keys

- (TSChainKey*)getOrCreateChainKey:(NSData *)theirEphemeral {
    if ([self hasReceiverChain:theirEphemeral]) {
        return [self chainKeyForEphemeral:(NSData*)theirEphemeral];
    } else{
        
        NSData *rootKey = [self rootKey];
        TSECKeyPair *ourEphemeral = [self senderEphemeral];
        TSChainKey *receiverChain = [self createChainWithTheirEphemeral:theirEphemeral ourEphemeral:ourEphemeral];
        TSECKeyPair *ourNewEphemeral = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
        TSChain *senderChain = [self createChainWithTheirEphemeral:theirEphemeral ourEphemeral:ourEphemeral];
        

            RootKey                 rootKey         = sessionRecord.getRootKey();
            ECKeyPair               ourEphemeral    = sessionRecord.getSenderEphemeralPair();
            Pair<RootKey, ChainKey> receiverChain   = rootKey.createChain(theirEphemeral, ourEphemeral);
            ECKeyPair               ourNewEphemeral = Curve.generateKeyPairForType(Curve.DJB_TYPE);
            Pair<RootKey, ChainKey> senderChain     = receiverChain.first.createChain(theirEphemeral, ourNewEphemeral);
            
            sessionRecord.setRootKey(senderChain.first);
            sessionRecord.addReceiverChain(theirEphemeral, receiverChain.second);
            sessionRecord.setPreviousCounter(sessionRecord.getSenderChainKey().getIndex()-1);
            sessionRecord.setSenderChain(ourNewEphemeral, senderChain.second);
            
            return receiverChain.second;
    }
    
    else {
        RootKey                 rootKey         = sessionRecord.getRootKey();
        ECKeyPair               ourEphemeral    = sessionRecord.getSenderEphemeralPair();
        Pair<RootKey, ChainKey> receiverChain   = rootKey.createChain(theirEphemeral, ourEphemeral);
        ECKeyPair               ourNewEphemeral = Curve.generateKeyPairForType(Curve.DJB_TYPE);
        Pair<RootKey, ChainKey> senderChain     = receiverChain.first.createChain(theirEphemeral, ourNewEphemeral);
        
        sessionRecord.setRootKey(senderChain.first);
        sessionRecord.addReceiverChain(theirEphemeral, receiverChain.second);
        sessionRecord.setPreviousCounter(sessionRecord.getSenderChainKey().getIndex()-1);
        sessionRecord.setSenderChain(ourNewEphemeral, senderChain.second);
        
        return receiverChain.second;
    }
}

- (TSChainKey*)chainKeyForEphemeral:(NSData*)theirEphemeral{
    // Perform DB lookup and return
    
    return nil;
}

- (TSChainKey*)createChainWithTheirEphemeral:(NSData*)theirEphemeral ourEphemeral:(TSECKeyPair*)ephemeral{
    

}


#pragma mark My Identity Key

- (TSECKeyPair*)myIdentityKey{
    return [TSUserKeysDatabase identityKey];
}

#pragma mark Helper methods

+(NSData*)masterKeyAlice:(TSECKeyPair*)ourIdentityKeyPair ourEphemeral:(TSECKeyPair*)ourEphemeralKeyPair theirIdentityPublicKey:(NSData*)theirIdentityPublicKey theirEphemeralPublicKey:(NSData*)theirEphemeralPublicKey {
    NSMutableData *masterKey = [NSMutableData data];
    [masterKey appendData:[ourIdentityKeyPair generateSharedSecretFromPublicKey:theirEphemeralPublicKey]];
    [masterKey appendData:[ourEphemeralKeyPair generateSharedSecretFromPublicKey:theirIdentityPublicKey]];
    [masterKey appendData:[ourEphemeralKeyPair generateSharedSecretFromPublicKey:theirEphemeralPublicKey]];
    return masterKey;
}

+(NSData*)masterKeyBob:(TSECKeyPair*)ourIdentityKeyPair ourEphemeral:(TSECKeyPair*)ourEphemeralKeyPair theirIdentityPublicKey:(NSData*)theirIdentityPublicKey theirEphemeralPublicKey:(NSData*)theirEphemeralPublicKey {
    NSMutableData *masterKey = [NSMutableData data];
    [masterKey appendData:[ourEphemeralKeyPair generateSharedSecretFromPublicKey:theirIdentityPublicKey]];
    [masterKey appendData:[ourIdentityKeyPair generateSharedSecretFromPublicKey:theirEphemeralPublicKey]];
    [masterKey appendData:[ourEphemeralKeyPair generateSharedSecretFromPublicKey:theirEphemeralPublicKey]];
    return masterKey;
}

@end
