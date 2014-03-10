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
@class TSWhisperMessageKeys;
@class TSPreKeyWhisperMessage;

typedef void(^keyStoreFetchNumberCompletionBlock) (NSNumber* number);
typedef void(^keyStoreFetchDataCompletionBlock) (NSData* data);
typedef void(^keyStoreSetDataCompletionBlock) (BOOL success);
typedef void(^keyStoreFetchArrayCompletionBlock)(NSError **error, NSArray* array);
typedef void(^keyStoreFetchKeyPairCompletionBlock)(NSError **error, TSECKeyPair* keyPair);

typedef NS_ENUM(NSInteger, TSChainType) {
  TSSendingChain=0,
  TSReceivingChain
};

// TSGroupContextType, TSPushMessageFlags,TSWhisperMessageType are redundant with the protocol buffers, and is meant to abate the spread of objective-c++. otherwise this file, and any that rely on the types would be obj-c++.
// non-ideal.

typedef NS_ENUM(NSInteger, TSGroupContextType) {
    TSUnknownGroupContext = 0,
    TSUpdateGroupContext = 1,
    TSDeliverGroupContext = 2,
    TSQuitGroupContext =3
};

typedef NS_ENUM(NSInteger, TSPushMessageFlags) {
    TSEndSession = 1
};



typedef NS_ENUM(NSInteger, TSWhisperMessageType) {
  TSUnknownMessageType =0,
  TSEncryptedWhisperMessageType = 1,
  TSIgnoreOnIOSWhisperMessageType=2, // on droid this is the prekey bundle message irrelevant for us
  TSPreKeyWhisperMessageType = 3,
  TSUnencryptedWhisperMessageType = 4,

};

@protocol AxolotlPersistantStorage  <NSObject>
#warning for efficiency, past the prototyping stage we will want to group these requests
/* Axolotl Protocol variables. Persistant storage per thread. */
// we have both SENDING and RECEIVING key chains
//RK           : 32-byte root key which gets updated by DH ratchet

+(NSData*) RK:(TSThread*)thread;
+(void) setRK:(NSData*)key onThread:(TSThread*)thread;

//CKs, CKr     : 32-byte chain keys (used for forward-secrecy updating)

+(NSData*) CK:(TSThread*)thread onChain:(TSChainType)chain;
+(void) setCK:(NSData*)key onThread:(TSThread*)thread onChain:(TSChainType)chain;

//DHIs, DHIr   : DH or ECDH Identity keys
+(NSData*) ephemeralOfReceivingChain:(TSThread*)thread;
+(void) setEphemeralOfReceivingChain:(NSData*)key onThread:(TSThread*)thread;


+(TSECKeyPair*) ephemeralOfSendingChain:(TSThread*)thread;
+(void) setEphemeralOfSendingChain:(TSECKeyPair*)key onThread:(TSThread*)thread;

//Ns, Nr       : Message numbers (reset to 0 with each new ratchet)
+(NSNumber*) N:(TSThread*)thread onChain:(TSChainType)chain;
+(void) setN:(NSNumber*)num onThread:(TSThread*)thread onChain:(TSChainType)chain;

// sets N to N+1 returns value of N prior to setting,  Message numbers (reset to 0 with each new ratchet)
+(NSNumber*) NThenPlusPlus:(TSThread*)thread onChain:(TSChainType)chain;

//PNs          : Previous message numbers (# of msgs sent under prev ratchet) only relevant for sending chain
+(NSNumber*)PNs:(TSThread*)thread;
+(void)setPNs:(NSNumber*)num onThread:(TSThread*)thread;

#warning update a queue of last chain keys... in case a message is delayed in transit.

@end

@protocol AxolotlEphemeralStorageMessagingKeys  <NSObject>
@property(nonatomic,strong) NSData* cipherKey;
@property(nonatomic,strong) NSData* macKey;
@end




