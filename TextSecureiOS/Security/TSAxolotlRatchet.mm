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
#import "TSMessageKeys.h"
#import "TSHKDF.h"
#import "RKCK.h"
#import "TSContact.h"
#import "Constants.h"
#import "TSMessageIncoming.h"
#import "TSMessageOutgoing.h"
#import "TSPrekey.h"



@implementation TSAxolotlRatchet

#pragma mark Public methods

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
    
    TSChainKey *chainKey = [self getOrCreateChainKeys:session theirEphemeral:theirEphemeral];
    TSMessageKeys *messageKeys = [self getOrCreateMessageKeysForSession:session theirEphemeral:theirEphemeral chainKey:chainKey counter:counter];
    
    NSData *cipherText = message.message;
    
    NSString* contentString = [[NSString alloc] initWithData:[Cryptography decryptCTRMode:cipherText withKeys:messageKeys forVersion:[message version] withHMAC:message.hmac] encoding:NSUTF8StringEncoding];
    
    TSMessageIncoming *incomingMessage = [[TSMessageIncoming alloc] initWithMessageWithContent:contentString sender:session.contact.registeredID date:[NSDate date] attachements:nil group:nil state:TSMessageStateReceived];
    [TSMessagesDatabase storeSession:session];
    
    return incomingMessage;
}

+ (TSEncryptedWhisperMessage*)encryptMessage:(TSMessage*)message withSession:(TSSession*)session{
    
    if ([session hasPendingPreKey]) {
        [session clear];
        
        TSECKeyPair *ourEphemeralKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
        NSData *theirBaseKey = session.pendingPreKey.ephemeralKey;
        
        RKCK *rootAndReceivingChainKey = [RKCK initWithData:[self masterKeyAlice:[self myIdentityKey] ourEphemeral:ourEphemeralKey theirIdentityPublicKey:session.pendingPreKey.identityKey theirEphemeralPublicKey:session.pendingPreKey.ephemeralKey]];
        
        TSECKeyPair *sendingKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
        [session setRootKey:rootAndReceivingChainKey.RK];
        [session setSenderChain:sendingKey chainkey:rootAndReceivingChainKey.CK];
        [session addReceiverChain:theirBaseKey chainKey:[rootAndReceivingChainKey createChainWithEphemeral:sendingKey fromTheirProvideEphemeral:theirBaseKey].CK];
    }
    
    TSChainKey *chainKey = [session senderChainKey];
    TSMessageKeys *messageKeys = [chainKey messageKeys];
    TSECKeyPair *senderEphemeral = [session senderEphemeral];
    int previousCounter = session.PN;
    
    NSData* computedHMAC;
    NSData *cipherText = [Cryptography encryptCTRMode:[message.content dataUsingEncoding:NSUTF8StringEncoding] withKeys:messageKeys forVersion:[self currentProtocolVersion] computedHMAC:&computedHMAC];
    
    TSEncryptedWhisperMessage *encryptedMessage = [[TSEncryptedWhisperMessage alloc] initWithEphemeralKey:senderEphemeral.publicKey previousCounter:[NSNumber numberWithInt:previousCounter] counter:[NSNumber numberWithInt:chainKey.index] encryptedMessage:cipherText forVersion:[self currentProtocolVersion] withHMAC:computedHMAC];
    
    if ([session hasPendingPreKey]) {
        
        TSPrekey *prekey = [session pendingPreKey];
        
        encryptedMessage = [[TSPreKeyWhisperMessage alloc]initWithPreKeyId:[NSNumber numberWithInt:prekey.prekeyId] senderPrekey:prekey.ephemeralKey senderIdentityKey:prekey.identityKey message:[encryptedMessage getTextSecure_WhisperMessage] forVersion:[self currentProtocolVersion]];

    }
    
    [session setSenderChainKey:[chainKey nextChainKey]];
    
    [TSMessagesDatabase storeSession:session];
    
    
    return encryptedMessage;
    
}

+ (TSChainKey*)getOrCreateChainKeys:(TSSession*)session theirEphemeral:(NSData*)theirEphemeral{
    
    if ([session hasReceiverChain:theirEphemeral]) {
        return [session receiverChainKey:theirEphemeral];
    } else{
        
        TSECKeyPair *newEphemeralKeyPair = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
        
        RKCK *rootKey = [RKCK initWithRK:session.rootKey CK:nil];
        
        RKCK *receiverChainKey = [rootKey createChainWithEphemeral:session.senderEphemeral fromTheirProvideEphemeral:theirEphemeral];
        RKCK *sendingChainKey = [rootKey createChainWithEphemeral:newEphemeralKeyPair fromTheirProvideEphemeral:theirEphemeral];
        session.rootKey = receiverChainKey.RK;
        [session addReceiverChain:theirEphemeral chainKey:receiverChainKey.CK];
        [session setPN:session.senderChainKey.index-1];
        [session setSenderChain:newEphemeralKeyPair chainkey:sendingChainKey.CK];
        return receiverChainKey.CK;
    }
}

+ (TSMessageKeys*)getOrCreateMessageKeysForSession:(TSSession*)session theirEphemeral:(NSData*)ephemeral chainKey:(TSChainKey*)chainKey counter:(int)counter{
    if (chainKey.index > counter) {
        if ([session hasMessageKeysForEphemeral:ephemeral counter:counter]) {
            [session removeMessageKeysForEphemeral:ephemeral counter:counter];
        } else{
            throw [NSException exceptionWithName:@"Received message with old counter!" reason:@"" userInfo:@{}];

        }
    }
    
    if (chainKey.index - counter > 500) {
        throw [NSException exceptionWithName:@"Over 500 messages into the future!" reason:@"" userInfo:@{}];
    }
    
    while (chainKey.index < counter) {
        TSMessageKeys *messageKeys = [chainKey messageKeys];
        [session setMessageKeysWithEphemeral:ephemeral messageKey:messageKeys];
        chainKey = chainKey.nextChainKey;
    }
    
    [session setReceiverChainKeyWithEphemeral:ephemeral chainKey:chainKey];
    
    return [chainKey messageKeys];
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

    TSSession *session = [TSMessagesDatabase sessionForRegisteredId:contact.registeredID deviceId:deviceId];
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

+ (TSECKeyPair*)myIdentityKey{
    return [TSUserKeysDatabase identityKey];
}
    
+ (NSData*)currentProtocolVersion{
    int version = 2;
    return [NSData dataWithBytes:&version length:sizeof(version)];
}


#pragma mark Helper methods

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

@end