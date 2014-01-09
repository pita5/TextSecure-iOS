//
//  TSProtocolManagerForThread.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/6/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TSMessage;
@class TSThread;
@class ECKeyPair;
@class TSMessageSignal;
@class TSECKeyPair;
@class TSPreKeyWhisperMessage;
typedef NS_ENUM(NSInteger, TSParty) {
  TSSender=0,
  TSReceiver
};
typedef NS_ENUM(NSInteger, TSWhisperMessageType) {
  TSUnencryptedWhisperMessageType = 0,
  TSEncryptedWhisperMessageType = 1,
  TSIgnoreOnIOSWhisperMessageType=2, // on droid this is the prekey bundle message irrelevant for us
  TSPreKeyWhisperMessageType = 3
};

@protocol AxolotlPersistantStorage  <NSObject>
#warning for efficiency, past the prototyping stage we will want to group these requests
/* Axolotl Protocol variables. Persistant storage per thread. */
//RK           : 32-byte root key which gets updated by DH ratchet
-(NSData*) getRK:(TSThread*)thread;
-(void) setRK:(NSData*)key onThread:(TSThread*)thread;
//CKs, CKr     : 32-byte chain keys (used for forward-secrecy updating)
-(NSData*) getCK:(TSThread*)thread forParty:(TSParty)party;
-(void) setCK:(NSData*)key onThread:(TSThread*)thread forParty:(TSParty)party;
//DHIs, DHIr   : DH or ECDH Identity keys
-(NSData*) getDHI:(TSThread*)thread forParty:(TSParty)party;
-(void) setDHI:(NSData*)key onThread:(TSThread*)thread forParty:(TSParty)party;
//DHRs, DHRr   : DH or ECDH Ratchet keys
-(NSData*) getDHR:(TSThread*)thread forParty:(TSParty)party;
-(void) setDHR:(NSData*)key onThread:(TSThread*)thread forParty:(TSParty)party;
//Ns, Nr       : Message numbers (reset to 0 with each new ratchet)
-(NSNumber*) getN:(TSThread*)thread forParty:(TSParty)party;
-(void) setN:(NSNumber*)num onThread:(TSThread*)thread forParty:(TSParty)party;
//PNs          : Previous message numbers (# of msgs sent under prev ratchet)
-(NSNumber*)getPNs:(TSThread*)thread;
-(void)setPNs:(NSNumber*)num onThread:(TSThread*)thread;
@end

@protocol AxolotlEphemeralStorage  <NSObject>
/* Protocol variables. Ephemeral storage per thread */
//MK  : message key
@property(nonatomic,strong) NSData* MK;
//  try_skipped_header_and_message_keys() : Attempt to decrypt the message with skipped-over
// message keys (and their associated header keys) from persistent storage.
-(void)trySkippedHeaderAndMessageKeys;
//stage_skipped_header_and_message_keys() : Given a current header key, a current message number,
//a future message number, and a chain key, calculates and stores all skipped-over message keys
//(if any) in a staging area where they can later be committed, along with their associated
//header key.  Returns the chain key and message key corresponding to the future message number.
-(void)stageSkippedHeaderAndMessageKeys;
//commit_skipped_header_and_message_keys() : Commits any skipped-over message keys from the
//staging area to persistent storage (along with their associated header keys).
-(void)commitSkippedHeaderAndMessageKeys;

@end


@protocol AxolotlEphemeralStorageSending  <NSObject,AxolotlEphemeralStorage>
-(void) setSendEphemerals;

@end


@protocol AxolotlEphemeralStorageReceiving  <NSObject,AxolotlEphemeralStorage>
//Np  : Purported message number
@property(nonatomic,strong) NSData* purportedN;
//PNp : Purported previous message number
@property(nonatomic,strong) NSData* purportedPN;
//CKp : Purported new chain key
@property(nonatomic,strong) NSData* purportedCK;
//DHp : Purported new DHr
@property(nonatomic,strong) NSData* purportedDHr;
//RKp : Purported new root key
@property(nonatomic,strong) NSData* purportedRK;
//NHKp, HKp : Purported new header keys
@property(nonatomic,strong) NSData* purportedNHK;
@property(nonatomic,strong) NSData* purportedHK;

-(void) setReceiveEphemerals;

@end


@protocol AxolotlKeyAgreement <NSObject>

-(void)keyAgreement:(TSPreKeyWhisperMessage*)keyAgreementMessage forParty:(TSParty) party;
-(NSData*)masterKeyAlice:(TSECKeyPair*)ourIdentityKeyPair ourEphemeral:(TSECKeyPair*)ourEphemeralKeyPair theirIdentityPublicKey:(NSData*)theirIdentityPublicKey theirEphemeralPublicKey:(NSData*)theirEphemeralPublicKey;
-(NSData*)masterKeyBob:(TSECKeyPair*)ourIdentityKeyPair ourEphemeral:(TSECKeyPair*)ourEphemeralKeyPair theirIdentityPublicKey:(NSData*)theirIdentityPublicKey theirEphemeralPublicKey:(NSData*)theirEphemeralPublicKey;

@end

@protocol TSProtocol <NSObject,AxolotlKeyAgreement>

-(void) sendMessage:(TSMessage*) message onThread:(TSThread*)thread;
-(NSData*) encryptMessage:(TSMessage*)message onThread:(TSThread*)thread;
-(TSMessage*) decryptMessageSignal:(TSMessageSignal*)whisperMessage;

@end

