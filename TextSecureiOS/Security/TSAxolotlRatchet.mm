//
//  TSAxolotlRatchet.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/12/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSAxolotlRatchet.hh"

#import "TSMessage.h"
#import "TSContact.h"
#import "NSData+Base64.h"
#import "TSSubmitMessageRequest.h"
#import "TSMessagesManager.h"
#import "TSKeyManager.h"
#import "Cryptography.h"
#import "TSMessage.h"
#import "TSMessagesDatabase.h"
#import "TSUserKeysDatabase.h"
#import "TSMessageSignal.hh"
#import "TSPushMessageContent.hh"
#import "TSWhisperMessage.hh"
#import "TSEncryptedWhisperMessage.hh"
#import "TSPreKeyWhisperMessage.hh"
#import "TSRecipientPrekeyRequest.h"
#import "TSWhisperMessageKeys.h"
#import "TSHKDF.h"
#import "RKCK.h"
#import "TSContact.h"

@interface TSAxolotlRatchet ()

@end


@implementation TSAxolotlRatchet

#pragma mark Public methods

+ (TSWhisperMessageKeys*)decryptionKeysForSession:(TSSession*)session ephemeral:(NSData*)ephemeral counter:(int)counter{
    TSChainKey *chainKey = [self getOrCreateChainKey:session ephemeral:ephemeral];
    
    
    
}

+ (TSWhisperMessageKeys*)encryptionKeyForSession:(TSSession*)session{
    
}


#pragma mark Private methods

+ (TSChainKey*)getOrCreateChainKey:(TSSession*)session ephemeral:(NSData*)ephemeral{
    if ([session ]) {
        <#statements#>
    }
}

private ChainKey getOrCreateChainKey(SessionRecordV2 sessionRecord, ECPublicKey theirEphemeral)
throws InvalidMessageException
{
    try {
        if (sessionRecord.hasReceiverChain(theirEphemeral)) {
            return sessionRecord.getReceiverChainKey(theirEphemeral);
        } else {
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
    } catch (InvalidKeyException e) {
        throw new InvalidMessageException(e);
    }
}


#pragma mark Helper methods


+(TSWhisperMessageKeys*) ratchetSetupFirstSender:(NSData*)theirIdentity theirEphemeralKey:(NSData*)theirEphemeral{
    TSECKeyPair *ourIdentityKey = [TSUserKeysDatabase identityKey];
    TSECKeyPair *ourEphemeralKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
    NSData* ourMasterKey = [self masterKeyAlice:ourIdentityKey ourEphemeral:ourEphemeralKey   theirIdentityPublicKey:theirIdentity theirEphemeralPublicKey:theirEphemeral];
    RKCK* receivingChain = [self initialRootKey:ourMasterKey];
    TSECKeyPair* nextEphemeral = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
    RKCK* sendingChain = [receivingChain createChainWithNewEphemeral:nextEphemeral fromTheirProvideEphemeral:theirEphemeral]; // This will be used
    [receivingChain saveReceivingChainOnThread:self.thread withTheirEphemeral:theirEphemeral];
    [sendingChain saveSendingChainOnThread:self.thread withMyNewEphemeral:nextEphemeral];
    return ourEphemeralKey;
}

+(TSWhisperMessage*) ratchetSetupFirstReceiver:(NSData*)theirIdentityKey theirEphemeralKey:(NSData*)theirEphemeralKey withMyPrekeyId:(NSNumber*)preKeyId{
    /* after this we will have the CK of the Receiving Chain */
    TSECKeyPair *ourEphemeralKey = [TSUserKeysDatabase preKeyWithId:[preKeyId unsignedLongValue]];
    TSECKeyPair *ourIdentityKey =  [TSUserKeysDatabase identityKey];
    NSData* ourMasterKey = [self masterKeyBob:ourIdentityKey ourEphemeral:ourEphemeralKey theirIdentityPublicKey:theirIdentityKey theirEphemeralPublicKey:theirEphemeralKey];
    RKCK* sendingChain = [self initialRootKey:ourMasterKey];
    [sendingChain saveSendingChainOnThread:self.thread withMyNewEphemeral:ourEphemeralKey];
}

+(void) updateChainsOnReceivedMessage:(NSData*)theirNewEphemeral{
    RKCK *currentSendingChain = [RKCK currentSendingChain:self.thread];
    RKCK *newReceivingChain = [currentSendingChain createChainWithNewEphemeral:currentSendingChain.ephemeral fromTheirProvideEphemeral:theirNewEphemeral];
    TSECKeyPair* newSendingKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
    RKCK *newSendingChain = [newReceivingChain createChainWithNewEphemeral:newSendingKey fromTheirProvideEphemeral:theirNewEphemeral];
    [newReceivingChain saveReceivingChainOnThread:self.thread withTheirEphemeral:theirNewEphemeral];
    [newSendingChain saveSendingChainOnThread:self.thread withMyNewEphemeral:newSendingKey];
}


#pragma mark Ratchet helper methods

+(TSWhisperMessageKeys*)nextMessageKeysOnChain:(TSChainType)chain{
    NSData *CK = [TSMessagesDatabase CK:self.thread onChain:chain];
    int hmacKeyMK = 0x01;
    int hmacKeyCK = 0x02;
    NSData* nextMK = [Cryptography computeHMAC:CK withHMACKey:[NSData dataWithBytes:&hmacKeyMK length:sizeof(hmacKeyMK)]];
    NSData* nextCK = [Cryptography computeHMAC:CK  withHMACKey:[NSData dataWithBytes:&hmacKeyCK length:sizeof(hmacKeyCK)]];
    [TSMessagesDatabase setCK:nextCK onThread:self.thread onChain:chain];
    [TSMessagesDatabase NThenPlusPlus:self.thread onChain:chain];
    return [self deriveTSWhisperMessageKeysFromMessageKey:nextMK];
}

+(RKCK*) initialRootKey:(NSData*)masterKey {
    return [RKCK withData:[TSHKDF deriveKeyFromMaterial:masterKey outputLength:64 info:[@"WhisperText" dataUsingEncoding:NSUTF8StringEncoding]]];
}

+(TSWhisperMessageKeys*) deriveTSWhisperMessageKeysFromMessageKey:(NSData*)nextMessageKey_MK {
    NSData* newCipherKeyAndMacKey  = [TSHKDF deriveKeyFromMaterial:nextMessageKey_MK outputLength:64 info:[@"WhisperMessageKeys" dataUsingEncoding:NSUTF8StringEncoding]];
    NSData* cipherKey = [newCipherKeyAndMacKey subdataWithRange:NSMakeRange(0, 32)];
    NSData* macKey = [newCipherKeyAndMacKey subdataWithRange:NSMakeRange(32, 32)];
    // we want to return something here  or use this locally
    return [[TSWhisperMessageKeys alloc] initWithCipherKey:cipherKey macKey:macKey];
}

#pragma mark Encryption - Decryption Methods



@end
