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
@class TSEncryptedWhisperMessage;
@class TSPreKeyWhisperMessage;
@class TSWhisperMessageKeys;
typedef NS_ENUM(NSInteger, TSChainType) {
  TSSendingChain=0,
  TSReceivingChain
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
// we have both SENDING and RECEIVING key chains
//RK           : 32-byte root key which gets updated by DH ratchet
+(NSData*) getRK:(TSThread*)thread;
+(void) setRK:(NSData*)key onThread:(TSThread*)thread;
//CKs, CKr     : 32-byte chain keys (used for forward-secrecy updating)
+(NSData*) getCK:(TSThread*)thread onChain:(TSChainType)chain;
+(void) setCK:(NSData*)key onThread:(TSThread*)thread onChain:(TSChainType)chain;
//DHIs, DHIr   : DH or ECDH Identity keys
+(NSData*) getEphemeralPublicKeyOfChain:(TSThread*)thread onChain:(TSChainType)chain;
+(void) setEphemeralPublicKeyOfChain:(NSData*)key onThread:(TSThread*)thread onChain:(TSChainType)chain;
//Ns, Nr       : Message numbers (reset to 0 with each new ratchet)
+(NSNumber*) getN:(TSThread*)thread onChain:(TSChainType)chain;
+(void) setN:(NSNumber*)num onThread:(TSThread*)thread onChain:(TSChainType)chain;
// sets N to N+1 returns value of N prior to setting,  Message numbers (reset to 0 with each new ratchet)
+(NSNumber*) getNPlusPlus:(TSThread*)thread onChain:(TSChainType)chain;

//PNs          : Previous message numbers (# of msgs sent under prev ratchet) only relevant for sending chain
+(NSNumber*)getPNs:(TSThread*)thread;
+(void)setPNs:(NSNumber*)num onThread:(TSThread*)thread;

#warning update a queue of last chain keys... in case a message is delayed in transit.

@end




@protocol AxolotlEphemeralStorageMessagingKeys  <NSObject>
@property(nonatomic,strong) NSData* cipherKey;
@property(nonatomic,strong) NSData* macKey;
@end




