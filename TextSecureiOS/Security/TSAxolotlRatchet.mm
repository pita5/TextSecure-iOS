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
#import "Constants.h"
#import "TSMessageIncoming.h"
#import "TSMessageOutgoing.h"
#import "TSPrekey.h"


@implementation TSAxolotlRatchet

#pragma mark Public methods

// Method for outgoing messages
+ (BOOL) needsPrekey:(TSContact*)contact{
    return [TSMessagesDatabase sessionExistsForContact:contact];
}

+ (TSWhisperMessage*)whisperMessageWith:(TSMessage*)outgoingMessage deviceId:(int)deviceId preKey:(TSPrekey*)prekey{
    
    return nil;
}

+ (TSWhisperMessage*)whisperMessageWith:(TSMessage*)outgoingMessage deviceId:(int)deviceId{
    return nil;
}

// Method for incoming messages
+ (TSMessage*)messageWithWhisperMessage:(TSEncryptedWhisperMessage*)message fromContact:(TSContact*)contact{
    
    TSSession *session = [TSMessagesDatabase sessionForRegisteredId:contact.registeredID deviceId:1];
    
    if ([message isKindOfClass:[TSPreKeyWhisperMessage class]]) {
        TSPreKeyWhisperMessage *preKeyWhisperMessage = (TSPreKeyWhisperMessage*)message;
        
        if (!contact.identityKey) {
            contact.identityKey = preKeyWhisperMessage.identityKey;
        } else{
            if (![contact.identityKey isEqualToData:preKeyWhisperMessage.identityKey]) {
                throw [NSException exceptionWithName:@"IdentityKeyMismatch" reason:@"" userInfo:@{}];
#warning we'll want to store that message to retry decrypting later if user wants to continue
            }
        }

        session = [self processPrekey:[[TSPrekey alloc]initWithIdentityKey:preKeyWhisperMessage.identityKey ephemeral:preKeyWhisperMessage.ephemeralKey prekeyId:[preKeyWhisperMessage.preKeyId intValue]]withContact:contact deviceId:1];
    }
    
    if (!session) {
        throw [NSException exceptionWithName:@"NoSessionFoundForDecryption" reason:@"" userInfo:@{}];
    }
    
    return [self decryptMessage:message withSession:session];
}


+ (TSMessage*)decryptMessage:(TSEncryptedWhisperMessage*)message withSession:(TSSession*)session{
    
    NSData *theirEphemeral = message.ephemeralKey;
    int counter = [message.counter intValue];
    
    NSData *chainKey = [self getOrCreateChainKeys:session theirEphemeral:theirEphemeral];
    
    
    ECPublicKey      theirEphemeral    = ciphertextMessage.getSenderEphemeral();
    int              counter           = ciphertextMessage.getCounter();
    ChainKey         chainKey          = getOrCreateChainKey(sessionRecord, theirEphemeral);
    MessageKeys      messageKeys       = getOrCreateMessageKeys(sessionRecord, theirEphemeral,
                                                                chainKey, counter);
    
    ciphertextMessage.verifyMac(messageKeys.getMacKey());
    
    byte[] plaintext = getPlaintext(messageKeys, ciphertextMessage.getBody());
    
    sessionRecord.clearPendingPreKey();
    sessionRecord.save();
    
    return plaintext;
    
    
}

+ (TSChainKey*)getOrCreateChainKeys:(TSSession*)session theirEphemeral:(NSData*)theirEphemeral{
    
    if ([session hasReceiverChain:theirEphemeral]) {
        return [session receiverChainKey:theirEphemeral];
    } else{
        
        TSECKeyPair *newEphemeralKeyPair = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
        
        RKCK *rootKey = [RKCK initWithRK:session.rootKey CK:nil];
        
        RKCK *receiverChainKey = [rootKey createChainWithEphemeral:session.ephemeralOutgoing fromTheirProvideEphemeral:theirEphemeral];
        RKCK *sendingChainKey = [rootKey createChainWithEphemeral:newEphemeralKeyPair fromTheirProvideEphemeral:theirEphemeral];
        session.rootKey = receiverChainKey.RK;
        [session addReceiverChain:theirEphemeral chainKey:receiverChainKey.CK];
        [session setPN:session.senderChainKey.index-1];
        [session setSenderChain:newEphemeralKeyPair chainkey:sendingChainKey.CK];
        return receiverChainKey.CK;
    }
}

+ (NSData*)getOrCreateMessageKeysForSession:(TSSession*)session theirEphemeral:(NSData*)ephemeral chainKey:(TSChainKey*)chainKey counter:(int)counter{
    
    
    
    private MessageKeys getOrCreateMessageKeys(SessionRecordV2 sessionRecord,
                                               ECPublicKey theirEphemeral,
                                               ChainKey chainKey, int counter)
    throws InvalidMessageException
    {
        if (chainKey.getIndex() > counter) {
            if (sessionRecord.hasMessageKeys(theirEphemeral, counter)) {
                return sessionRecord.removeMessageKeys(theirEphemeral, counter);
            } else {
                throw new InvalidMessageException("Received message with old counter!");
            }
        }
        
        if (chainKey.getIndex() - counter > 500) {
            throw new InvalidMessageException("Over 500 messages into the future!");
        }
        
        while (chainKey.getIndex() < counter) {
            MessageKeys messageKeys = chainKey.getMessageKeys();
            sessionRecord.setMessageKeys(theirEphemeral, messageKeys);
            chainKey = chainKey.getNextChainKey();
        }
        
        sessionRecord.setReceiverChainKey(theirEphemeral, chainKey.getNextChainKey());
        return chainKey.getMessageKeys();
    }
}



#pragma mark PreKey Utils - Sending and Receiving PrekeyMessages


/**
 *  Helper method for processing an incoming prekey message and setting up the ratchet
 *
 *  @param prekey  Prekey used
 *  @param contact Contact information from receiver
 *
 *  @return Returns a session with the initialized ratchet
 */

+ (TSSession*)processPrekey:(TSPrekey*)prekey withContact:(TSContact*)contact deviceId:(int)deviceId{

    TSSession *session = [[TSSession alloc] initWithContact:contact deviceId:deviceId];
    TSECKeyPair *preKeyPair = [TSUserKeysDatabase preKeyWithId:prekey.prekeyId];
    
    if (preKeyPair){
        
        // Clear previous records for this session
        [TSMessagesDatabase deleteSession:session];
    
        //3-way DHE
        RKCK *rootAndSendingChainKey = [RKCK initWithData:[self masterKeyBob:[self myIdentityKey] ourEphemeral:preKeyPair theirIdentityPublicKey:prekey.identityKey theirEphemeralPublicKey:prekey.ephemeralKey]];
        
        // Generate new sending key
        TSECKeyPair *sendingEphemeralKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
        
        [session setRootKey:rootAndSendingChainKey.RK];
        [session setSenderChain:sendingEphemeralKey chainkey:rootAndSendingChainKey.CK];
        
        if (preKeyPair.preKeyId != kLastResortKeyId) {
            // Delete that preKey!
        }
        
        return session;
        
    } else{
        
        // if session exists for that contact we just go straight to decryption process.
        
        // We probably have already processed that message.
#warning properly do error management
        @throw ([NSException exceptionWithName:@"" reason:@"" userInfo:@{}]);
    }
    
    return session;
}

#pragma mark Identity
+ (TSECKeyPair*)myIdentityKey{
    return [TSUserKeysDatabase identityKey];
}

#pragma mark Private methods





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

+(void) updateChainsOnReceivedMessage:(NSData*)theirNewEphemeral{
    RKCK *currentSendingChain = [RKCK currentSendingChain:self.thread];
    RKCK *newReceivingChain = [currentSendingChain createChainWithNewEphemeral:currentSendingChain.ephemeral fromTheirProvideEphemeral:theirNewEphemeral];
    TSECKeyPair* newSendingKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
    RKCK *newSendingChain = [newReceivingChain createChainWithNewEphemeral:newSendingKey fromTheirProvideEphemeral:theirNewEphemeral];
    [newReceivingChain saveReceivingChainOnThread:self.thread withTheirEphemeral:theirNewEphemeral];
    [newSendingChain saveSendingChainOnThread:self.thread withMyNewEphemeral:newSendingKey];
    
}

+ (NSData*)masterKeyAlice:(TSECKeyPair*)ourIdentityKeyPair ourEphemeral:(TSECKeyPair*)ourEphemeralKeyPair theirIdentityPublicKey:(NSData*)theirIdentityPublicKey theirEphemeralPublicKey:(NSData*)theirEphemeralPublicKey {
    NSMutableData *masterKey = [NSMutableData data];
    [masterKey appendData:[ourIdentityKeyPair generateSharedSecretFromPublicKey:theirEphemeralPublicKey]];
    [masterKey appendData:[ourEphemeralKeyPair generateSharedSecretFromPublicKey:theirIdentityPublicKey]];
    [masterKey appendData:[ourEphemeralKeyPair generateSharedSecretFromPublicKey:theirEphemeralPublicKey]];
    return masterKey;
}

+ (NSData*)masterKeyBob:(TSECKeyPair*)ourIdentityKeyPair ourEphemeral:(TSECKeyPair*)ourEphemeralKeyPair theirIdentityPublicKey:(NSData*)theirIdentityPublicKey theirEphemeralPublicKey:(NSData*)theirEphemeralPublicKey {
    NSMutableData *masterKey = [NSMutableData data];
    
    if (!(ourEphemeralKeyPair && theirEphemeralPublicKey && ourIdentityKeyPair && theirIdentityPublicKey)) {
        DLog(@"Some parameters of are not defined");
    }
    
    [masterKey appendData:[ourEphemeralKeyPair generateSharedSecretFromPublicKey:theirIdentityPublicKey]];
    [masterKey appendData:[ourIdentityKeyPair generateSharedSecretFromPublicKey:theirEphemeralPublicKey]];
    [masterKey appendData:[ourEphemeralKeyPair generateSharedSecretFromPublicKey:theirEphemeralPublicKey]];
    return masterKey;
}

#pragma mark Ratchet helper methods

+(TSWhisperMessageKeys*) deriveTSWhisperMessageKeysFromMessageKey:(NSData*)nextMessageKey_MK {
    NSData* newCipherKeyAndMacKey  = [TSHKDF deriveKeyFromMaterial:nextMessageKey_MK outputLength:64 info:[@"WhisperMessageKeys" dataUsingEncoding:NSUTF8StringEncoding]];
    NSData* cipherKey = [newCipherKeyAndMacKey subdataWithRange:NSMakeRange(0, 32)];
    NSData* macKey = [newCipherKeyAndMacKey subdataWithRange:NSMakeRange(32, 32)];
    // we want to return something here  or use this locally
    return [[TSWhisperMessageKeys alloc] initWithCipherKey:cipherKey macKey:macKey];
}

@end