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
    
#warning protocol buffers don't support multiple device IDs for now. Just use the first one found.
    //TSSession *session = [TSMessagesDatabase sessionForRegisteredId:contact.registeredID deviceId:?];
    
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

        session = [self processPrekey:[[TSPrekey alloc]initWithIdentityKey:preKeyWhisperMessage.identityKey ephemeral:preKeyWhisperMessage.ephemeralKey prekeyId:[preKeyWhisperMessage.preKeyId intValue]]withContact:contact];
    }
    
    if (!session) {
        throw [NSException exceptionWithName:@"NoSessionFoundForDecryption" reason:@"" userInfo:@{}];
    }
    
    return [self decryptMessageWithSession:session];
}


#pragma mark PreKey utils


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

+ (TSMessage*)decryptMessageWithSession:(TSSession*)session{
    
}

#pragma mark Identity
+ (TSECKeyPair*)myIdentityKey{
    return [TSUserKeysDatabase identityKey];
}

#pragma mark Private methods

+ (TSChainKey*)getOrCreateChainKey:(TSSession*)session ephemeral:(NSData*)ephemeral{
    if ([session hasReceiverChain:ephemeral]) {
        
        switch (messageType) {
                
            case TSPreKeyWhisperMessageType:{
                // get a contact's prekey
                TSContact* contact = [[TSContact alloc] initWithRegisteredID:message.recipientId];
                TSThread* thread = [TSThread threadWithContacts:@[[[TSContact alloc] initWithRegisteredID:message.recipientId]]save:YES];
                [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRecipientPrekeyRequest alloc] initWithRecipient:contact] success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    switch (operation.response.statusCode) {
                        case 200:{
                            
                            NSLog(@"Prekey fetched :) ");
                            
                            // Extracting the recipients keying material from server payload
                            
                            NSData* theirIdentityKey = [NSData dataFromBase64String:[responseObject objectForKey:@"identityKey"]];
                            NSData* theirEphemeralKey = [NSData dataFromBase64String:[responseObject objectForKey:@"publicKey"]];
                            NSNumber* theirPrekeyId = [responseObject objectForKey:@"keyId"];
                            
                            // remove the leading "0x05" byte as per protocol specs
                            if (theirEphemeralKey.length == 33) {
                                theirEphemeralKey = [theirEphemeralKey subdataWithRange:NSMakeRange(1, 32)];
                            }
                            
                            // remove the leading "0x05" byte as per protocol specs
                            if (theirIdentityKey.length == 33) {
                                theirIdentityKey = [theirIdentityKey subdataWithRange:NSMakeRange(1, 32)];
                            }
                            
                            // Retreiving my keying material to construct message
                            
                            TSECKeyPair *currentEphemeral = [ratchet ratchetSetupFirstSender:theirIdentityKey theirEphemeralKey:theirEphemeralKey];
                            NSData* computedHMAC;
                            NSData* version = [NSData dataWithBytes:&textSecureVersion length:sizeof(textSecureVersion)];
                            NSData *encryptedMessage = [ratchet encryptTSMessage:message withKeys:[ratchet nextMessageKeysOnChain:TSSendingChain] withCTR:[NSNumber numberWithInt:0] forVersion:version computedHMAC:&computedHMAC];
                            TSECKeyPair *nextEphemeral = [TSMessagesDatabase ephemeralOfSendingChain:thread]; // nil
                            NSData* encodedPreKeyWhisperMessage = [TSPreKeyWhisperMessage constructFirstMessage:encryptedMessage theirPrekeyId:theirPrekeyId myCurrentEphemeral:currentEphemeral myNextEphemeral:nextEphemeral forVersion:version  withHMAC:computedHMAC];
                            [TSAxolotlRatchet receiveMessage:encodedPreKeyWhisperMessage];
                            [[TSMessagesManager sharedManager] submitMessageTo:message.recipientId message:[encodedPreKeyWhisperMessage base64EncodedString] ofType:TSPreKeyWhisperMessageType];
                            
                            // nil
                            break;
                        }
                        default:
                            DLog(@"error sending message");
#warning Add error handling if not able to get contacts prekey
                            break;
                    }
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#warning right now it is not succesfully processing returned response, but is giving 200
                    DLog(@"Not a 200");
                    
                }];
                
                break;
            }
            case TSEncryptedWhisperMessageType: {
#warning clearly this needs filled in
                // unsupported
                break;
            }
            default:
                break;
        }
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

@end