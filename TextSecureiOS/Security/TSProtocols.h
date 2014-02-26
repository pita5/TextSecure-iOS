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
@class TSMessageSignal;
@class TSECKeyPair;
@class TSEncryptedWhisperMessage;
@class TSPreKeyWhisperMessage;
@class TSWhisperMessageKeys;

typedef void(^keyStoreFetchNumberCompletionBlock) (NSNumber* number);
typedef void(^keyStoreFetchDataCompletionBlock) (NSData* data);
typedef void(^keyStoreSetDataCompletionBlock) (BOOL success);
typedef void(^keyStoreFetchKeyPairCompletionBlock)(TSECKeyPair* keyPair);

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
+(void) getRK:(TSThread*)thread withCompletionBlock:(keyStoreFetchDataCompletionBlock) block;

+(void) setRK:(NSData*)key onThread:(TSThread*)thread withCompletionBlock:(keyStoreSetDataCompletionBlock) block;
//CKs, CKr     : 32-byte chain keys (used for forward-secrecy updating)
+(void) getCK:(TSThread*)thread onChain:(TSChainType)chain withCompletionBlock:(keyStoreFetchDataCompletionBlock) block;
+(void) setCK:(NSData*)key onThread:(TSThread*)thread onChain:(TSChainType)chain withCompletionBlock:(keyStoreSetDataCompletionBlock) block;
//DHIs, DHIr   : DH or ECDH Identity keys
+(void) getEphemeralOfReceivingChain:(TSThread*)thread withCompletionBlock:(keyStoreFetchDataCompletionBlock) block;
+(void) setEphemeralOfReceivingChain:(NSData*)key onThread:(TSThread*)thread withCompletionBlock:(keyStoreSetDataCompletionBlock) block;

+(void) getEphemeralOfSendingChain:(TSThread*)thread withCompletionBlock:(keyStoreFetchKeyPairCompletionBlock) block;

+(void) setEphemeralOfSendingChain:(TSECKeyPair*)key onThread:(TSThread*)thread withCompletionBlock:(keyStoreSetDataCompletionBlock) block;
//Ns, Nr       : Message numbers (reset to 0 with each new ratchet)
+(void) getN:(TSThread*)thread onChain:(TSChainType)chain withCompletionBlock:(keyStoreFetchNumberCompletionBlock) block;
;
+(void) setN:(NSNumber*)num onThread:(TSThread*)thread onChain:(TSChainType)chain withCompletionBlock:(keyStoreSetDataCompletionBlock) block;
// sets N to N+1 returns value of N prior to setting,  Message numbers (reset to 0 with each new ratchet)
+(void) getNPlusPlus:(TSThread*)thread onChain:(TSChainType)chain withCompletionBlock:(keyStoreFetchNumberCompletionBlock) block;


//PNs          : Previous message numbers (# of msgs sent under prev ratchet) only relevant for sending chain
+(void)getPNs:(TSThread*)thread withCompletionBlock:(keyStoreFetchNumberCompletionBlock) block;
;
+(void)setPNs:(NSNumber*)num onThread:(TSThread*)thread withCompletionBlock:(keyStoreSetDataCompletionBlock) block;

#warning update a queue of last chain keys... in case a message is delayed in transit.

@end

@protocol AxolotlEphemeralStorageMessagingKeys  <NSObject>
@property(nonatomic,strong) NSData* cipherKey;
@property(nonatomic,strong) NSData* macKey;
@end




