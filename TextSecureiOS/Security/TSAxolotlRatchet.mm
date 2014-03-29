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
#import "TSWhisperMessage.hh"
#import "TSEncryptedWhisperMessage.hh"
#import "TSPreKeyWhisperMessage.hh"
#import "TSRecipientPrekeyRequest.h"
#import "TSMessageKeys.h"
#import "TSHKDF.h"
#import "RKCK.h"
#import "TSContact.h"
#import "Constants.h"
#import "TSMessageIncoming.h"
#import "TSMessageOutgoing.h"
#import "TSPrekey.h"
#import "NSData+TSKeyVersion.h"



@implementation TSAxolotlRatchet



#pragma mark Public methods

// Method for incoming messages
+ (TSMessage*)decryptWhisperMessage:(TSWhisperMessage*)message withSession:(TSSession *)session{
    if ([message isKindOfClass:[TSPreKeyWhisperMessage class]]) {
        TSPreKeyWhisperMessage *preKeyWhisperMessage = (TSPreKeyWhisperMessage*)message;
        session = [self initializeSessionAsBob:session withPreKeyWhisperMessage:preKeyWhisperMessage];
        if (!session) {
            throw [NSException exceptionWithName:@"NoSessionFoundForDecryption" reason:@"" userInfo:@{}];
        }
        return [self decryptMessage:[[TSEncryptedWhisperMessage alloc] initWithTextSecureProtocolData:preKeyWhisperMessage.message]
                        withSession:session];
    }
    else if ([message isKindOfClass:[TSEncryptedWhisperMessage class]]) {
        return [self decryptMessage: (TSEncryptedWhisperMessage*)message
                        withSession:session];
    }
    else {
        throw [NSException exceptionWithName:@"Unrecognized TSWhisperMessageType. Can't cast. This is a programmer bug." reason:@"" userInfo:@{}];
    }
}

+ (TSMessage*)decryptMessage:(TSEncryptedWhisperMessage*)message withSession:(TSSession*)sessionRecord{
    NSData *theirEphemeral = message.ephemeralKey;
    int counter = [message.counter intValue];
    TSChainKey *chainKey = [self getOrCreateChainKeys:sessionRecord theirEphemeral:theirEphemeral];
    TSMessageKeys *messageKeys = [self getOrCreateMessageKeysForSession:sessionRecord
                                                         theirEphemeral:theirEphemeral
                                                               chainKey:chainKey
                                                                counter:counter];
    NSData *cipherTextMessage = message.message;
    NSString* decryptedMessageString = [[NSString alloc] initWithData:[Cryptography decryptCTRMode:cipherTextMessage
                                                                                          withKeys:messageKeys
                                                                                        forVersion:[message version]
                                                                                          withHMAC:message.hmac]
                                                             encoding:NSUTF8StringEncoding];
    TSMessageIncoming *incomingMessage = [[TSMessageIncoming alloc] initMessageWithContent:decryptedMessageString
                                                                                    sender:sessionRecord.contact.registeredID
                                                                                      date:[NSDate date]
                                                                              attachements:nil
                                                                                     group:nil
                                                                                     state:TSMessageStateReceived];
    [TSMessagesDatabase storeSession:sessionRecord];

    return incomingMessage;
}

+ (TSWhisperMessage*)encryptMessage:(TSMessage*)message withSession:(TSSession*)sessionRecord{
    
    if (sessionRecord.fetchedPrekey) {
        [self initializeSessionAsAlice:sessionRecord];
    }
    
    TSChainKey *chainKey = [sessionRecord senderChainKey];
    TSMessageKeys *messageKeys = [chainKey messageKeys];
    TSECKeyPair *senderEphemeral = [sessionRecord senderEphemeral];
    int previousCounter = sessionRecord.PN;
    
    NSData* computedHMAC;
    NSData *ciphertextBody = [Cryptography encryptCTRMode:[message.content dataUsingEncoding:NSUTF8StringEncoding] withKeys:messageKeys forVersion:[self currentProtocolVersion] computedHMAC:&computedHMAC];
    
    TSWhisperMessage *encryptedMessage;
    if ([sessionRecord hasPendingPreKey]) {
        encryptedMessage = [TSPreKeyWhisperMessage constructFirstMessage:ciphertextBody
                                                           theirPrekeyId:[NSNumber numberWithInt:sessionRecord.pendingPreKey.prekeyId]
                                                      myCurrentEphemeral:sessionRecord.pendingPreKey.ephemeralKey
                                                         myNextEphemeral:sessionRecord.senderEphemeral.publicKey
                                                              forVersion:[self currentProtocolVersion]
                                                                withHMAC:computedHMAC];

    }
    else {
        encryptedMessage = [[TSEncryptedWhisperMessage alloc] initWithEphemeralKey:senderEphemeral.publicKey
                                                                   previousCounter:[NSNumber numberWithInt:previousCounter]
                                                                           counter:[NSNumber numberWithInt:chainKey.index]
                                                                  encryptedMessage:ciphertextBody
                                                                        forVersion:[self currentProtocolVersion]
                                                                          withHMAC:computedHMAC];
    }

    [sessionRecord setSenderChainKey:[chainKey nextChainKey]];
    [TSMessagesDatabase storeSession:sessionRecord];
    
    return encryptedMessage;
}

+ (TSChainKey*)getOrCreateChainKeys:(TSSession*)session theirEphemeral:(NSData*)theirEphemeral{
    
    if ([session hasReceiverChain:theirEphemeral]) {
        return [session receiverChainKey:theirEphemeral];
    }
    else {
        // Receiving chain setup
        RKCK *rootKey = [RKCK initWithRK:session.rootKey CK:nil];
        TSECKeyPair *ourEphemeral = session.senderEphemeral;
        RKCK *receiverChain= [rootKey createChainWithEphemeral:ourEphemeral
                                     fromTheirProvideEphemeral:theirEphemeral];
        
        // Sending chain setup
        TSECKeyPair *ourNewSendingEphemeral = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
        RKCK *senderChain = [rootKey createChainWithEphemeral:ourNewSendingEphemeral fromTheirProvideEphemeral:theirEphemeral];
        [session setSenderChain:ourNewSendingEphemeral chainkey:senderChain.CK];

        // Saving in session
        session.rootKey = receiverChain.RK;
        [session addReceiverChain:theirEphemeral chainKey:receiverChain.CK];
        [session setPN:session.senderChainKey.index-1];
        return receiverChain.CK;
    }
}

+ (TSMessageKeys*)getOrCreateMessageKeysForSession:(TSSession*)session theirEphemeral:(NSData*)theirEphemeral chainKey:(TSChainKey*)chainKey counter:(int)counter{
    
    if (chainKey.index > counter) {
        if ([session hasMessageKeysForEphemeral:theirEphemeral counter:counter]) {
            [session removeMessageKeysForEphemeral:theirEphemeral counter:counter];
        }
        else{
            throw [NSException exceptionWithName:@"Received message with old counter!" reason:@"" userInfo:@{}];
        }
    }
    
    if (chainKey.index - counter > 500) {
        throw [NSException exceptionWithName:@"Over 500 messages into the future!" reason:@"" userInfo:@{}];
    }
    if(chainKey.index>0) {
#warning we need to track down why chainKey.index is -1 on first receive. 
        while (chainKey.index < counter) {
            TSMessageKeys *messageKeys = [chainKey messageKeys];
            [session setMessageKeysWithEphemeral:theirEphemeral messageKey:messageKeys];
            chainKey = chainKey.nextChainKey;
        }
    }
    [session setReceiverChainKeyWithEphemeral:theirEphemeral chainKey:chainKey];
    return [chainKey messageKeys];
}

+ (TSECKeyPair*)myIdentityKey{
    return [TSUserKeysDatabase identityKey];
}

/**
 *  The current version data. First 4 bits are the current version and the last 4 ones are the lowest version we support.
 *
 *  @return Current version data
 */

+ (NSData*)currentProtocolVersion{
    NSUInteger index = 0b00100010;
    NSData *versionByte = [NSData dataWithBytes:&index length:1];
    return versionByte;
}


#pragma mark Private methods
+ (void) initializeSessionAsAlice:(TSSession*) sessionRecord {
    // corbett refactored:
    // See slide 9 http://www.slideshare.net/ChristineCorbettMora/axolotl-protocol-an-illustrated-primer
    int idPrekeyUsed = sessionRecord.fetchedPrekey.prekeyId;
#warning verify if previous identity key stored!
    [sessionRecord clear];
    /* A,A0,B,B0 */
    TSECKeyPair *ourIdentityKey = [self myIdentityKey]; //A
    TSECKeyPair *ourBaseKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0]; // A0
    NSData* theirIdentityKey = sessionRecord.fetchedPrekey.identityKey; // B
    NSData *theirEphemeralKey = sessionRecord.fetchedPrekey.ephemeralKey; // B0
    TSECKeyPair *newSendingKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0]; // A1
    // Initial 3ECDH(A,A0,B,B0)
    RKCK *receivingChain = [RKCK initWithData:[self masterKeyAlice:ourIdentityKey
                                                      ourEphemeral:ourBaseKey
                                            theirIdentityPublicKey:theirIdentityKey
                                           theirEphemeralPublicKey:theirEphemeralKey]];
    
    RKCK* sendingChain = [receivingChain createChainWithEphemeral:newSendingKey
                                        fromTheirProvideEphemeral:theirEphemeralKey];
    
    [sessionRecord addReceiverChain:theirEphemeralKey chainKey:receivingChain.CK];
    [sessionRecord setSenderChain:newSendingKey chainkey:sendingChain.CK];
    [sessionRecord setRootKey:sendingChain.RK];

    [sessionRecord setPendingPreKey:[[TSPrekey alloc] initWithIdentityKey:nil
                                                                ephemeral:ourBaseKey.publicKey
                                                                 prekeyId:idPrekeyUsed]];
}

+(TSSession*) initializeSessionAsBob:(TSSession*) sessionRecord withPreKeyWhisperMessage:(TSPreKeyWhisperMessage*)preKeyWhisperMessage{
    
    TSContact *contact = sessionRecord.contact;
    int deviceId = sessionRecord.deviceId;

    if (!contact.identityKey) {
        contact.identityKey = preKeyWhisperMessage.identityKey;
        [[NSNotificationCenter defaultCenter] postNotificationName:contact.registeredID object:self];
    }
    else{
        if (![contact.identityKey isEqualToData:preKeyWhisperMessage.identityKey]) {
            #warning we'll want to store that message to retry decrypting later if user wants to continue
            throw [NSException exceptionWithName:@"IdentityKeyMismatch" reason:@"" userInfo:@{}];
        }
    }
    
    TSPrekey *prekey = [[TSPrekey alloc] initWithIdentityKey:preKeyWhisperMessage.identityKey
                                                  ephemeral:preKeyWhisperMessage.baseKey
                                                   prekeyId:[preKeyWhisperMessage.preKeyId intValue]];

    TSECKeyPair *ourEphemeralKey = [TSUserKeysDatabase preKeyWithId:prekey.prekeyId];
    
    if (ourEphemeralKey){
        [TSMessagesDatabase deleteSession:sessionRecord];
        TSSession *newSession = [TSMessagesDatabase sessionForRegisteredId:contact.registeredID deviceId:deviceId];
         // Initial 3ECDH(A,A0,B,B0)
        RKCK *sendingChain = [RKCK initWithData:[self masterKeyBob:[self myIdentityKey]
                                                      ourEphemeral:ourEphemeralKey
                                            theirIdentityPublicKey:prekey.identityKey
                                           theirEphemeralPublicKey:prekey.ephemeralKey]];
        
        [newSession setSenderChain:ourEphemeralKey chainkey:sendingChain.CK]; // this will be unused
        [newSession setRootKey:sendingChain.RK];
        
        if (ourEphemeralKey.preKeyId != kLastResortKeyId) {
            #warning Delete that preKey!
        }
        return newSession;
        
    }
    else {
        #warning properly do error management
        /* if session exists for that contact we just go straight to decryption process.
            We probably have already processed that message. */
        @throw ([NSException exceptionWithName:@"NoPrekeyWithID" reason:@"A message was received with an unknown prekey" userInfo:@{}]);
    }

}


+ (NSData*)masterKeyAlice:(TSECKeyPair*)ourIdentityKeyPair ourEphemeral:(TSECKeyPair*)ourEphemeralKeyPair theirIdentityPublicKey:(NSData*)theirIdentityPublicKey theirEphemeralPublicKey:(NSData*)theirEphemeralPublicKey {
    NSMutableData *masterKey = [NSMutableData data];
    [masterKey appendData:[ourIdentityKeyPair  generateSharedSecretFromPublicKey:theirEphemeralPublicKey]];
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
    [masterKey appendData:[ourIdentityKeyPair  generateSharedSecretFromPublicKey:theirEphemeralPublicKey]];
    [masterKey appendData:[ourEphemeralKeyPair generateSharedSecretFromPublicKey:theirEphemeralPublicKey]];
    return masterKey;
}



@end