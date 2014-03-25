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

    TSContact *contact = session.contact;
    TSEncryptedWhisperMessage *encryptedWhispeMessageToDecrypt;
    if ([message isKindOfClass:[TSPreKeyWhisperMessage class]]) {
        TSPreKeyWhisperMessage *preKeyWhisperMessage = (TSPreKeyWhisperMessage*)message;
        if (!contact.identityKey) {
            contact.identityKey = [preKeyWhisperMessage.identityKey removeVersionByte];
        } else{
            if (![contact.identityKey isEqualToData:[preKeyWhisperMessage.identityKey removeVersionByte]]) {
                throw [NSException exceptionWithName:@"IdentityKeyMismatch" reason:@"" userInfo:@{}];
#warning we'll want to store that message to retry decrypting later if user wants to continue
            }
        }
        
        session = [self processPrekey:[[TSPrekey alloc]initWithIdentityKey:[preKeyWhisperMessage.identityKey removeVersionByte] ephemeral:[preKeyWhisperMessage.baseKey removeVersionByte] prekeyId:[preKeyWhisperMessage.preKeyId intValue]]withContact:contact deviceId:1];
        encryptedWhispeMessageToDecrypt = [[TSEncryptedWhisperMessage alloc] initWithTextSecureProtocolData:preKeyWhisperMessage.message];
        NSLog(@"debugDescription: A1 received for decryption: %@\n",[encryptedWhispeMessageToDecrypt.ephemeralKey removeVersionByte]);
    }
    else if ([message isKindOfClass:[TSEncryptedWhisperMessage class]]) {
        encryptedWhispeMessageToDecrypt = (TSEncryptedWhisperMessage*)message;
    }
    else {
        throw [NSException exceptionWithName:@"Unrecognized TSWhisperMessageType. Can't cast. This is a programmer bug." reason:@"" userInfo:@{}];
    }
    if (!session) {
        throw [NSException exceptionWithName:@"NoSessionFoundForDecryption" reason:@"" userInfo:@{}];
    }
    return [self decryptMessage:encryptedWhispeMessageToDecrypt withSession:session];
}

+ (TSMessage*)decryptMessage:(TSEncryptedWhisperMessage*)message withSession:(TSSession*)session{
    // here is where we need to generate new sending and receiving chains!
    NSData *theirEphemeral = [message.ephemeralKey removeVersionByte];
    int counter = [message.counter intValue];
    
    TSChainKey *chainKey = [self getOrCreateChainKeys:session theirEphemeral:theirEphemeral];
    TSMessageKeys *messageKeys = [self getOrCreateMessageKeysForSession:session theirEphemeral:theirEphemeral chainKey:chainKey counter:counter];
    NSLog(@"Decrypt %@ %@",[chainKey debugDescription],[messageKeys debugDescription]);
    
    NSData *cipherText = message.message;
    
    NSString* contentString = [[NSString alloc] initWithData:[Cryptography decryptCTRMode:cipherText withKeys:messageKeys forVersion:[message version] withHMAC:message.hmac] encoding:NSUTF8StringEncoding];
    // TODO: this is currently returning nil-mac is not matching.
#warning if mac doesn't match for example, the decrypt ctr mode will return nil
    TSMessageIncoming *incomingMessage = [[TSMessageIncoming alloc] initMessageWithContent:contentString sender:session.contact.registeredID date:[NSDate date] attachements:nil group:nil state:TSMessageStateReceived];
    [TSMessagesDatabase storeSession:session];

    return incomingMessage;
}

+ (TSWhisperMessage*)encryptMessage:(TSMessage*)message withSession:(TSSession*)session{
    
    if (session.fetchedPrekey) {
        // corbett refactored:
        // See slide 9 http://www.slideshare.net/ChristineCorbettMora/axolotl-protocol-an-illustrated-primer
        int idPrekeyUsed = session.fetchedPrekey.prekeyId; // doing this before as [session clear] sounds like it should delete this even if it didn't
        [session clear];
        TSECKeyPair *ourIdentityKey = [self myIdentityKey]; //A
        TSECKeyPair *ourEphemeralKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0]; // A0
        NSData* theirIdentityKey = session.fetchedPrekey.identityKey; // B
        NSData *theirEphemeralKey = session.fetchedPrekey.ephemeralKey; // B0
        RKCK *rootAndReceivingChainKey = [RKCK initWithData:[self masterKeyAlice:ourIdentityKey ourEphemeral:ourEphemeralKey theirIdentityPublicKey:theirIdentityKey theirEphemeralPublicKey:theirEphemeralKey]];  // 3ECDH(A,A0,B,B0)
        NSLog(@"3ECDH Encyption receiving\n: %@\n",[rootAndReceivingChainKey debugDescription]);
        [session setRootKey:rootAndReceivingChainKey.RK];
        [session addReceiverChain:theirEphemeralKey chainKey:rootAndReceivingChainKey.CK];
        
        TSECKeyPair *ourNewEphemeralKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0]; // A1
        RKCK* rootAndSendingChainKey = [rootAndReceivingChainKey createChainWithEphemeral:ourNewEphemeralKey fromTheirProvideEphemeral:theirEphemeralKey];
        [session setSenderChain:ourNewEphemeralKey chainkey:rootAndSendingChainKey.CK];

        NSLog(@"Encryption sending\n (2nd) %@\n B0 pub: %@\n A1 pub: %@\n",[rootAndSendingChainKey debugDescription],theirEphemeralKey,ourNewEphemeralKey.publicKey);

        [session setPendingPreKey:[[TSPrekey alloc] initWithIdentityKey:nil ephemeral:ourEphemeralKey.publicKey prekeyId:idPrekeyUsed]];
        // end corbett refactor
        
    }

    
    TSChainKey *chainKey = [session senderChainKey];
    TSMessageKeys *messageKeys = [chainKey messageKeys];
    
    NSLog(@"Encrypt %@ %@",[chainKey debugDescription],[messageKeys debugDescription]);
    TSECKeyPair *senderEphemeral = [session senderEphemeral];
    int previousCounter = session.PN;
    
    NSData* computedHMAC;
    NSData *cipherText = [Cryptography encryptCTRMode:[message.content dataUsingEncoding:NSUTF8StringEncoding] withKeys:messageKeys forVersion:[self currentProtocolVersion] computedHMAC:&computedHMAC];
    
    TSWhisperMessage *encryptedMessage;
    if ([session hasPendingPreKey]) {
        encryptedMessage = [TSPreKeyWhisperMessage constructFirstMessage:cipherText theirPrekeyId:[NSNumber numberWithInt:session.pendingPreKey.prekeyId] myCurrentEphemeral:session.pendingPreKey.ephemeralKey myNextEphemeral:session.senderEphemeral.publicKey forVersion:[self currentProtocolVersion] withHMAC:computedHMAC];

    } else{
        encryptedMessage = [[TSEncryptedWhisperMessage alloc] initWithEphemeralKey:senderEphemeral.publicKey previousCounter:[NSNumber numberWithInt:previousCounter] counter:[NSNumber numberWithInt:chainKey.index] encryptedMessage:cipherText forVersion:[self currentProtocolVersion] withHMAC:computedHMAC];
    }

    [session setSenderChainKey:[chainKey nextChainKey]];
    
    [TSMessagesDatabase storeSession:session];
    
    return encryptedMessage;
}

+ (TSChainKey*)getOrCreateChainKeys:(TSSession*)session theirEphemeral:(NSData*)theirEphemeral{
    
    if ([session hasReceiverChain:theirEphemeral]) {
        return [session receiverChainKey:theirEphemeral];
    }
    else{
        
        // corbett refactoring
        // the idea with moving code around is to ensure compile wise that variables we shouldn't be using yet aren't used in previous steps
        RKCK *rootKey = [RKCK initWithRK:session.rootKey CK:nil];
        RKCK *receiverChainKey = [rootKey createChainWithEphemeral:session.senderEphemeral fromTheirProvideEphemeral:theirEphemeral];
        [session addReceiverChain:theirEphemeral chainKey:receiverChainKey.CK];
        NSLog(@"Decrypting received message receiver chain:\n %@\n B0 public: %@\n A1 public: %@ \n",[receiverChainKey debugDescription],session.senderEphemeral.publicKey,theirEphemeral);

        TSECKeyPair *newSendingEphemeral = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
        RKCK *sendingChainKey = [rootKey createChainWithEphemeral:newSendingEphemeral fromTheirProvideEphemeral:theirEphemeral];
        NSLog(@"Decrypting received message new sending chain: \n %@ \n",[receiverChainKey debugDescription]);
        session.rootKey = receiverChainKey.RK;
        [session setPN:session.senderChainKey.index-1];
        [session setSenderChain:newSendingEphemeral chainkey:sendingChainKey.CK];
        return receiverChainKey.CK;
        //end corbett refactoring
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
        RKCK *rootAndSendingChainKey = [RKCK initWithData:[self masterKeyBob:[self myIdentityKey] ourEphemeral:preKeyPair theirIdentityPublicKey:prekey.identityKey theirEphemeralPublicKey:prekey.ephemeralKey]]; // 3ECDH(A,A0,B,B0)
        
        NSLog(@"3ECDH Decryption 1st sending:\n %@\n",[rootAndSendingChainKey debugDescription]);
        
        [session setRootKey:rootAndSendingChainKey.RK];
        // corbett refactored
        [session setSenderChain:preKeyPair chainkey:rootAndSendingChainKey.CK]; // this will be unused
        // end corbett refactor
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