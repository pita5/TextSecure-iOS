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
/* Axolotl Protocol variables. Persistant storage per thread */
//RK           : 32-byte root key which gets updated by DH ratchet
-(NSData*) getRK:(TSThread*)thread;
-(void) setRK:(NSData*)key onThread:(TSThread*)thread;
//HKs, HKr     : 32-byte header keys (send and recv versions)
-(NSData*) getHK:(TSThread*)thread forParty:(TSParty)party;
-(NSData*) setHK:(NSData*)key onThread:(TSThread*)thread forParty:(TSParty)party;
//NHKs, NHKr   : 32-byte next header keys (")
-(NSData*) getNHK:(TSThread*)thread forParty:(TSParty)party;
-(NSData*) setNHK:(NSData*)key onThread:(TSThread*)thread forParty:(TSParty)party;
//CKs, CKr     : 32-byte chain keys (used for forward-secrecy updating)
-(NSData*) getCK:(TSThread*)thread forParty:(TSParty)party;
-(NSData*) setCK:(NSData*)key onThread:(TSThread*)thread forParty:(TSParty)party;
//DHIs, DHIr   : DH or ECDH Identity keys
-(ECKeyPair*) getDHI:(TSThread*)thread forParty:(TSParty)party;
-(ECKeyPair*) setDHI:(NSData*)key onThread:(TSThread*)thread forParty:(TSParty)party;
//DHRs, DHRr   : DH or ECDH Ratchet keys
-(ECKeyPair*) getDHR:(TSThread*)thread forParty:(TSParty)party;
-(ECKeyPair*) setDHR:(NSData*)key onThread:(TSThread*)thread forParty:(TSParty)party;
//Ns, Nr       : Message numbers (reset to 0 with each new ratchet)
-(int) getN:(TSThread*)thread forParty:(TSParty)party;
-(int) setN:(int)num onThread:(TSThread*)thread forParty:(TSParty)party;
//PNs          : Previous message numbers (# of msgs sent under prev ratchet)
-(int)getPNs:(TSThread*)thread;
-(void)setPNs:(int)num onThread:(TSThread*)thread;
//ratchet_flag : True if the party will send a new DH ratchet key in next msg
-(BOOL) getRachetFlag:(TSThread*)thread;
-(BOOL) setRachetFlag:(BOOL)flag onThread:(TSThread*)thread;
//skipped_HK_MK : A list of stored message keys and their associated header keys
//for "skipped" messages, i.e. messages that have not been
//received despite the reception of more recent messages.
//Entries may be stored with a timestamp, and deleted after a
//certain age.
-(NSArray*) getSkippedHeaderAndMessageKeys:(TSThread*)thread;
-(void) setSkippedHeaderAndMessageKeys:(NSArray*)skippedHKMK onThread:(TSThread*)thread;
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

-(void)keyAgreement;
-(void)keyAgreementAlice;
-(void)keyAgreementBob;


@end

@protocol TSProtocol <NSObject,AxolotlKeyAgreement>

-(void) sendMessage:(TSMessage*) message onThread:(TSThread*)thread;
-(NSData*) encryptMessage:(TSMessage*)message onThread:(TSThread*)thread;
-(TSMessage*) decryptMessage:(NSData*)message onThread:(TSThread*)thread;


@end

