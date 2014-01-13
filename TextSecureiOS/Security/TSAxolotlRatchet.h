//
//  TSAxolotlRatchet.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/12/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSProtocols.h"
@class TSMessage;
@class TSThread;
@interface TSAxolotlRatchet : NSObject

#pragma mark public methods
+(void)processIncomingMessage:(NSData*)data;
+(void)processOutgoingMessage:(TSMessage*)message onThread:(TSThread*)thread ofType:(TSWhisperMessageType) messageType;
#pragma mark private methods

//
//@protocol AxolotlKeyAgreement <NSObject>
//// all relevant database methods set inside these. only gets aloud outside of them
//-(NSData*)masterKeyAlice:(TSECKeyPair*)ourIdentityKeyPair ourEphemeral:(TSECKeyPair*)ourEphemeralKeyPair theirIdentityPublicKey:(NSData*)theirIdentityPublicKey theirEphemeralPublicKey:(NSData*)theirEphemeralPublicKey;
//-(NSData*)masterKeyBob:(TSECKeyPair*)ourIdentityKeyPair ourEphemeral:(TSECKeyPair*)ourEphemeralKeyPair theirIdentityPublicKey:(NSData*)theirIdentityPublicKey theirEphemeralPublicKey:(NSData*)theirEphemeralPublicKey;
//
//-(TSWhisperMessageKeys*)initialRootKeyDerivation:(TSPreKeyWhisperMessage*)keyAgreementMessage onThread:(TSThread*)thread forParty:(TSParty) party; /* called when someone else initiazes a new session, as is indicated by the receipt of a PreKeyWhisperMessage */
//-(void) newRootKeyDerivationFromNewPublicEphemeral:(NSData*)newPublicEphemeral_DHR onThread:(TSThread*)thread forParty:(TSParty)party; /* called when new message received in a session, that is not a session initialization */
//-(NSData*)updateAndGetNextMessageKeyOnThread:(TSThread*)thread forParty:(TSParty)party; /* continues and existing chain */
//-(TSWhisperMessageKeys*) deriveTSWhisperMessageKeysFromMessageKey:(NSData*)nextMessageKey_MK; /* just parses 64 byte NSData into 32 byte cipher and mac keys, respectively*/
//
//-(NSData*)newRootKeyMaterialFromTheirEphermalPublic:(NSData*)theirEphemeralPublic onThread:(TSThread*)thread forParty:(TSParty) party;
//-(TSECKeyPair*)generateNewEphemeralKeyPairOnThread:(TSThread*)thread forParty:(TSParty)party; // generates and stores a new ephemeral key
//
//
//@end
//
//@protocol TSProtocol <NSObject,AxolotlKeyAgreement>
//
//-(void) sendMessage:(TSMessage*) message onThread:(TSThread*)thread ofType:(TSWhisperMessageType) messageType;
//-(NSData*) encryptTSMessage:(TSMessage*)message withKeys:(TSWhisperMessageKeys*)messageKeys withCTR:(NSNumber*)ctr;
//-(TSMessage*) decryptReceivedMessageSignal:(TSMessageSignal*)whisperMessage;
//
//
//
//@end
@end


