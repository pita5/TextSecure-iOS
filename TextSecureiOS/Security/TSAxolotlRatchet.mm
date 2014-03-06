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
    
    NSData *knownIdentityKey = contact.identityKey;
    
    if ([message isKindOfClass:[TSPreKeyWhisperMessage class]]) {
        TSPreKeyWhisperMessage *preKeyWhisperMessage = (TSPreKeyWhisperMessage*)message;
        
#warning Not sure if we should watch the user that the identity key changed here.
        knownIdentityKey = preKeyWhisperMessage.identityKey;
    }
    
    
    
    return [TSMessageIncoming alloc] initWithMessageWithContent:<#(NSString *)#> sender:<#(NSString *)#> date:<#(NSDate *)#> attachements:<#(NSArray *)#> group:<#(TSGroup *)#> state:<#(TSMessageIncomingState)#>
}


#pragma mark PreKey utils

- (BOOL)processPrekey:(TSPrekey*)prekey {
    
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
//    private ChainKey getOrCreateChainKey(SessionRecordV2 sessionRecord, ECPublicKey theirEphemeral)
//    throws InvalidMessageException
//    {
//        try {
//            if (sessionRecord.hasReceiverChain(theirEphemeral)) {
//                return sessionRecord.getReceiverChainKey(theirEphemeral);
//            } else {
//                RootKey                 rootKey         = sessionRecord.getRootKey();
//                ECKeyPair               ourEphemeral    = sessionRecord.getSenderEphemeralPair();
//                Pair<RootKey, ChainKey> receiverChain   = rootKey.createChain(theirEphemeral, ourEphemeral);
//                ECKeyPair               ourNewEphemeral = Curve.generateKeyPairForType(Curve.DJB_TYPE);
//                Pair<RootKey, ChainKey> senderChain     = receiverChain.first.createChain(theirEphemeral, ourNewEphemeral);
//                sessionRecord.setRootKey(senderChain.first);
//                sessionRecord.addReceiverChain(theirEphemeral, receiverChain.second);
//                sessionRecord.setPreviousCounter(sessionRecord.getSenderChainKey().getIndex()-1);
//                sessionRecord.setSenderChain(ourNewEphemeral, senderChain.second);
//
//                return receiverChain.second;
//            }
//        } catch (InvalidKeyException e) {
//            throw new InvalidMessageException(e);
//        }
//    }


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

@end